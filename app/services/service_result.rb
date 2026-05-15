# frozen_string_literal: true

class ServiceResult
  attr_reader :data, :error, :status

  def initialize(success:, data: {}, error: nil, status: :unprocessable_entity)
    @success = success
    @data = data
    @error = error
    @status = status
  end

  def success?
    @success
  end
end
