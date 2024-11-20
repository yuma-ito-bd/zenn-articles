# frozen_string_literal: true

require 'csv'

csv = CSV.read('utf8_with_bom.csv', encoding: 'bom|utf-8', headers: true)
puts "name:"
puts csv['name']

# Outputs:
# name:
# Tom
# Jerry
# Alice
