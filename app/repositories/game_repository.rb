# frozen_string_literal: true

class GameRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  index_name GameSearchable::ALIAS_NAME

  mapping dynamic: false do
    indexes :start_time, type: :date
    indexes :end_time, type: :date
    indexes :status, type: :keyword
    indexes :location, type: :geo_point
    indexes :min_tier, type: :integer
    indexes :max_tier, type: :integer
    indexes :players_count, type: :integer
    indexes :max_players, type: :integer
    indexes :match_type, type: :keyword
  end

  settings number_of_shards: 1, number_of_replicas: 0

  def initialize
    super(client: Elasticsearch::Model.client)
  end

  def deserialize(document)
    document['_source']
  end

  def index_game(game, target_index: nil)
    client.index(
      index: target_index || index_name,
      id: game.id,
      body: game.as_indexed_json
    )
  end

  def delete_game(game_id)
    client.delete(index: index_name, id: game_id)
  rescue Elastic::Transport::Transport::Errors::NotFound
    nil
  end

  def bulk_index(games, target_index: nil)
    games.each { |game| index_game(game, target_index: target_index) }
  end

  def create_versioned_index
    name = Game.new_index_name
    client.indices.create(
      index: name,
      body: { settings: settings.to_hash, mappings: mappings.to_hash }
    )
    name
  end

  def swap_alias(new_index)
    alias_name = GameSearchable::ALIAS_NAME
    old_indices = current_indices

    actions = old_indices.map { |idx| { remove: { index: idx, alias: alias_name } } }
    actions << { add: { index: new_index, alias: alias_name } }

    client.indices.update_aliases(body: { actions: actions })
    old_indices
  end

  def current_indices
    alias_name = GameSearchable::ALIAS_NAME
    client.indices.get_alias(name: alias_name).keys
  rescue Elastic::Transport::Transport::Errors::NotFound
    []
  end

  def delete_indices(indices)
    indices.each { |idx| client.indices.delete(index: idx) }
  end

  def alias_exists?
    client.indices.exists_alias?(name: GameSearchable::ALIAS_NAME)
  rescue Elastic::Transport::Transport::Errors::NotFound
    false
  end

  def refresh(target_index = nil)
    client.indices.refresh(index: target_index || index_name)
  end

  def all_game_indices
    client.cat.indices(format: 'json').pluck('index')
          .select { |name| name.start_with?(GameSearchable::ALIAS_NAME) }
  end

  def doc_count(index = nil)
    target = index || GameSearchable::ALIAS_NAME
    refresh(target)
    client.count(index: target)['count']
  end
end
