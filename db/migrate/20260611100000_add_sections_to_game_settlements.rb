# frozen_string_literal: true

class AddSectionsToGameSettlements < ActiveRecord::Migration[8.1]
  def up
    add_column :game_settlements, :sections, :json

    GameSettlement.reset_column_information
    GameSettlement.find_each do |s|
      arrived_ids = s.game.game_participations.where(arrived_at_court: true).pluck(:user_id)
      legacy_section = {
        'id' => SecureRandom.uuid,
        'label' => 'Phần 1',
        'mode' => s.mode,
        'expense_lines' => Array(s.expense_lines),
        'desired_female_price' => s.desired_female_price.to_i,
        'fixed_male_price' => s.fixed_male_price.to_i,
        'fixed_female_price' => s.fixed_female_price.to_i,
        'participant_ids' => arrived_ids
      }
      s.update_columns(sections: [legacy_section])
    end
  end

  def down
    remove_column :game_settlements, :sections
  end
end
