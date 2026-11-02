# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MismatchedSequenceType < Base # :nodoc:
      @description = "detect primary key sequences whose type is smaller than the column type"
      @config = {
        ignore_tables: {
          description: "tables whose primary key sequences should not be checked",
          global: true
        }
      }

      private

      # Rank determines what's "large enough": a sequence must have rank >= column rank.
      INTEGER_TYPE_RANKS = {
        "smallint" => 1,
        "integer" => 2,
        "bigint" => 3
      }.freeze

      def message(table:, column:, column_type:, sequence:, sequence_type:)
        "the sequence #{sequence} has type #{sequence_type} but " \
          "#{table}.#{column} is #{column_type} - change the sequence type to #{column_type}"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          pk_column = primary_key(table)
          next if pk_column.nil?

          column_type = normalize_integer_type(pk_column.sql_type)
          next if column_type.nil?

          sequence_name = sequence_for(table, pk_column.name)
          next if sequence_name.nil? || sequence_name.empty?

          sequence_type = sequence_data_type(sequence_name)
          next if sequence_type.nil?

          column_rank   = INTEGER_TYPE_RANKS[column_type]
          sequence_rank = INTEGER_TYPE_RANKS[sequence_type]
          next if column_rank.nil? || sequence_rank.nil?
          next if sequence_rank >= column_rank

          problem!(
            table: table,
            column: pk_column.name,
            column_type: column_type,
            sequence: sequence_name,
            sequence_type: sequence_type
          )
        end
      end

      def normalize_integer_type(sql_type)
        case sql_type
        when /\Asmallint\b/i then "smallint"
        when /\A(integer|int4)\b/i then "integer"
        when /\A(bigint|int8)\b/i then "bigint"
        end
      end

      # Returns the fully-qualified sequence name (e.g. "public.companies_id_seq")
      # associated with the given table column, or nil if there is none.
      # Works for both SERIAL and IDENTITY columns via pg_depend.
      def sequence_for(table_name, column_name)
        connection.select_value(<<~SQL)
          SELECT n.nspname || '.' || seq.relname
          FROM pg_class seq
          JOIN pg_namespace n ON n.oid = seq.relnamespace
          JOIN pg_depend dep
            ON dep.objid = seq.oid
           AND dep.classid = 'pg_class'::regclass
           AND dep.refobjid = #{connection.quote(table_name)}::regclass
           AND dep.refobjsubid = (
                 SELECT attnum FROM pg_attribute
                 WHERE attrelid = #{connection.quote(table_name)}::regclass
                   AND attname = #{connection.quote(column_name)}
               )
           AND dep.deptype IN ('a', 'i')
          WHERE seq.relkind = 'S'
          LIMIT 1
        SQL
      end

      # Returns the data type of the sequence as a normalised string
      # ("smallint", "integer", or "bigint").
      def sequence_data_type(sequence_name)
        connection.select_value(<<~SQL)
          SELECT seqtypid::regtype::text
          FROM pg_sequence
          WHERE seqrelid = #{connection.quote(sequence_name)}::regclass
        SQL
      end
    end
  end
end
