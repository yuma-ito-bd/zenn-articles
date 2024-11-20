# frozen_string_literal: true

require 'csv'

# CSV.tableを利用する方法
# CSV.readに headers: true, converters: :numeric, header_converters: :symbol を指定する方法と同等です。
# https://docs.ruby-lang.org/ja/latest/method/CSV/s/table.html
csv = CSV.table('utf8_with_bom.csv')
puts "name:"
puts csv[:name]

# Outputs:
# name:
# Tom
# Jerry
# Alice
