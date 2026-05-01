# frozen_string_literal: true

class ElasticsearchReindexer
  def initialize(repo)
    @repo = repo
  end

  def run
    new_index = @repo.create_versioned_index
    log "Created new index '#{new_index}'."

    count = reindex_all(new_index)
    @repo.refresh(new_index)
    log "Indexed #{count} games into '#{new_index}'."

    old_indices = @repo.swap_alias(new_index)
    log "Alias '#{GameSearchable::ALIAS_NAME}' now points to '#{new_index}'."

    delete_old(old_indices)
    log 'Blue-green reindex complete.'
  end

  private

  def reindex_all(target_index)
    count = 0
    Game.find_in_batches(batch_size: 1000) do |batch|
      @repo.bulk_index(batch, target_index: target_index)
      count += batch.size
      log "  Indexed #{count} games..."
    end
    count
  end

  def delete_old(old_indices)
    @repo.delete_indices(old_indices)
    old_indices.each { |idx| log "Deleted old index '#{idx}'." }
  end

  def log(message)
    Rails.logger.info(message)
  end
end
