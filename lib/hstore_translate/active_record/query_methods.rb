module HstoreTranslate
  module ActiveRecord
    module QueryMethods
      def order(*raw_args)
        args = raw_args.each_with_object([]) do |arg, args|
          case arg
          when Hash
            translated, plain = arg.partition do |attr, direction|
              translated_attrs.include?(attr) && ::ActiveRecord::QueryMethods::VALID_DIRECTIONS.include?(direction)
            end
            args.concat(translated.map { |attr, direction| "#{translated_column_name(attr)} #{direction}" })
            arg = plain.to_h
          when Symbol
            if translated_attrs.include?(arg)
              arg = translated_column_name(arg)
            end
          end
          args << arg
        end
        super(*args)
      end

      private

      def translated_column_name(column)
        translations_column = "#{column}_translations"
        table_column = "#{quoted_table_name}.#{connection.quote_column_name translations_column}"
        if I18n.respond_to?(:fallbacks)
          whens = I18n.fallbacks[I18n.locale].map do |locale|
            locale = sanitize locale
            "WHEN exist(#{table_column}, #{locale}) THEN #{table_column}->#{locale}"
          end.join(' ')
          "CASE #{whens} END"
        else
          "#{table_column}->#{sanitize I18n.locale}"
        end
      end
    end
  end
end
