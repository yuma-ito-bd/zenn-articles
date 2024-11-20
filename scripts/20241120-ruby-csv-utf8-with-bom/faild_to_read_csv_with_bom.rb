# frozen_string_literal: true

require 'csv'

csv = CSV.read('utf8_with_bom.csv', headers: true)
puts "name:"
puts csv['name']
puts "age:"
puts csv['age']

# Outputs:
# name:
#
#
#
# age:
# 20
# 22
# 25
