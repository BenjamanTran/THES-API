Skill::CODES.each do |code|
  Skill.find_or_create_by!(code: code)
end

puts "Seeded #{Skill.count} skills: #{Skill.pluck(:code).join(', ')}"
