class ServiceResult
  attr_reader :data, :error, :status

  def initialize(success:, data: {}, error: nil, status: nil)
    @success = success
    @data = data
    @error = error
    @status = status
  end

  def success?
    @success
  end
end
