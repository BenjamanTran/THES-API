# frozen_string_literal: true

namespace :elasticsearch do
  def repo
    @repo ||= GameRepository.new
  end

  desc 'Create initial index with alias (first-time setup)'
  task setup: :environment do
    if repo.alias_exists?
      puts "Alias '#{GameSearchable::ALIAS_NAME}' already exists."
      next
    end

    new_index = repo.create_versioned_index
    repo.swap_alias(new_index)
    puts "Created index '#{new_index}' with alias '#{GameSearchable::ALIAS_NAME}'."
  end

  desc 'Blue-green reindex'
  task reindex: :environment do
    ElasticsearchReindexer.new(repo).run
    puts 'Reindex complete. Check Rails logs for details.'
  end

  desc 'Show current alias and index info'
  task status: :environment do
    indices = repo.alias_exists? ? repo.current_indices : []
    indices.each { |idx| puts "#{GameSearchable::ALIAS_NAME} -> #{idx} (#{repo.doc_count(idx)} docs)" }
    puts 'No alias found. Run elasticsearch:setup first.' if indices.empty?
  end

  desc 'Delete all game indices and alias'
  task drop: :environment do
    indices = repo.all_game_indices
    repo.delete_indices(indices)
    indices.each { |idx| puts "Deleted #{idx}." }
    puts 'No indices found.' if indices.empty?
  end
end
