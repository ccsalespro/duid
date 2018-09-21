require "minitest/autorun"

require "pg"

class TestDuid < Minitest::Test
  def setup
    # Any other required connection settings should be specified with the PG* environment variables
    @conn = PG.connect dbname: 'duid_test'
    @conn.exec "begin;"

    conn.exec <<~SQL
      create table widgets (
        id bigint primary key,
        name text not null
      );
    SQL
  end

  def teardown
    @conn.exec "rollback;"
  end

  attr_reader :conn

  def test_set_default_to_next_duid_block
    conn.exec "select set_default_to_next_duid_block('widgets', 'id');"

    conn.exec "insert into widgets(name) values('test') returning id" do |result|
      assert_equal 1, result.num_tuples
    end
  end

  def test_duid_to_table
    conn.exec "select set_default_to_next_duid_block('widgets', 'id');"

    widget_id = nil
    conn.exec "insert into widgets(name) values('test') returning id" do |result|
      assert_equal 1, result.num_tuples
      widget_id = result[0]["id"]
    end

    assert widget_id

    table_name = nil
    conn.exec_params "select duid_to_table($1)", [widget_id.to_s] do |result|
      assert_equal 1, result.num_tuples
      table_name = result[0]["duid_to_table"]
    end

    assert_equal "widgets", table_name
  end
end
