class ApplicationService
  def self.call(...)
    new(...).call
  end

  private

  def success(data = {})
    ServiceResult.new(success: true, data: data)
  end

  def failure(error, status = :unprocessable_entity)
    ServiceResult.new(success: false, error: error, status: status)
  end
end
