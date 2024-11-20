# frozen_string_literal: true

require 'csv'

# header_converters: :symbol を指定する方法
# 文字列ではなくシンボルに変換することでBOMの影響を受けずに読み込むことができます。
csv = CSV.read('utf8_with_bom.csv', headers: true, header_converters: :symbol)
puts "name:"
puts csv[:name]

# Outputs:
# name:
# Tom
# Jerry
# Alice
