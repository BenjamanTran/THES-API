# frozen_string_literal: true

class Skill
  CODES = %w[smash clear drop drive net_shot lift push block kill].freeze

  attr_reader :code

  def initialize(code)
    @code = code
  end

  def name
    I18n.t("skills.#{code}")
  end

  def self.all
    CODES.map { |code| new(code) }
  end

  def self.find(code)
    raise ArgumentError, "Unknown skill: #{code}" if CODES.exclude?(code)

    new(code)
  end
end
