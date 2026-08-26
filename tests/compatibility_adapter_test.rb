require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'sqlite3'
require 'tmpdir'

class CompatibilityAdapterTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  ADAPTER = File.join(ROOT, 'compat', 'fbtxt2sqlite_compat.rb')
  FIXTURES = File.join(__dir__, 'fixtures', 'footballtxt')

  def run_import(fixture)
    Dir.mktmpdir('fbtxt2sqlite-compat') do |dir|
      db_path = File.join(dir, 'test.sqlite3')
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        ADAPTER,
        db_path,
        File.join(FIXTURES, fixture)
      )
      yield db_path, stdout, stderr, status
    end
  end

  def domain_counts(db_path)
    db = SQLite3::Database.new(db_path)
    %w[leagues events teams matches].to_h do |table|
      [table, db.get_first_value("SELECT COUNT(*) FROM #{table}")]
    end
  ensure
    db&.close
  end

  def rows(db_path, sql)
    db = SQLite3::Database.new(db_path)
    db.results_as_hash = true
    db.execute(sql).map { |row| row.reject { |key, _| key.is_a?(Integer) } }
  ensure
    db&.close
  end

  def test_minimal_fixture_imports_real_domain_rows
    run_import('minimal.txt') do |db_path, stdout, stderr, status|
      assert status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      counts = domain_counts(db_path)
      assert_operator counts['leagues'], :>, 0
      assert_operator counts['events'], :>, 0
      assert_operator counts['teams'], :>, 0
      assert_operator counts['matches'], :>, 0
    end
  end

  def test_supported_features_preserve_sections_groups_rounds_dates_and_scores
    run_import('supported_features.txt') do |db_path, stdout, stderr, status|
      assert status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"

      matches = rows(db_path, <<~SQL)
        SELECT m.date, m.time, m.score1ft, m.score2ft, m.score1ht, m.score2ht,
               m.score1et, m.score2et, m.score1p, m.score2p, r.name AS round_name
        FROM matches m
        LEFT JOIN event_rounds r ON r.id = m.event_round_id
        ORDER BY m.date
      SQL
      assert_equal 2, matches.length
      assert_equal '2025-08-15', matches[0]['date']
      assert_equal '19:00', matches[0]['time']
      assert_equal [1, 0, 0, 0], matches[0].values_at('score1ft', 'score2ft', 'score1ht', 'score2ht')
      assert_equal 'Group Stage, Round 1, Group A', matches[0]['round_name']
      assert_equal '2026-05-10', matches[1]['date']
      assert_equal [1, 1, 0, 0, 2, 2, 5, 4], matches[1].values_at(
        'score1ft', 'score2ft', 'score1ht', 'score2ht',
        'score1et', 'score2et', 'score1p', 'score2p'
      )
      assert_equal 'Knockout Stage, Final', matches[1]['round_name']
    end
  end

  def test_supported_status_is_persisted_without_inventing_a_score
    run_import('supported_status.txt') do |db_path, stdout, stderr, status|
      assert status.success?, "stdout:\n#{stdout}\nstderr:\n#{stderr}"
      match = rows(db_path, 'SELECT status, score1ft, score2ft FROM matches').fetch(0)
      assert_equal 'postponed', match['status']
      assert_nil match['score1ft']
      assert_nil match['score2ft']
    end
  end

  {
    'reject_reported.txt' => 'COMPAT_UNSUPPORTED_REPORTED',
    'reject_agg.txt' => 'COMPAT_UNSUPPORTED_AGG',
    'reject_bye.txt' => 'COMPAT_UNSUPPORTED_BYE',
    'reject_parser_error.txt' => 'COMPAT_PARSER_ERROR',
    'reject_ambiguous_stage.txt' => 'COMPAT_AMBIGUOUS_STAGE',
    'reject_unsupported_nesting.txt' => 'COMPAT_UNSUPPORTED_NESTING',
    'reject_missing_date.txt' => 'COMPAT_MISSING_DATE'
  }.each do |fixture, reason|
    define_method("test_#{File.basename(fixture, '.txt')}") do
      run_import(fixture) do |db_path, stdout, stderr, status|
        refute status.success?, "unexpected success:\n#{stdout}"
        assert_includes stderr, reason
        assert_equal(
          { 'leagues' => 0, 'events' => 0, 'teams' => 0, 'matches' => 0 },
          domain_counts(db_path),
          "stdout:\n#{stdout}\nstderr:\n#{stderr}"
        )
      end
    end
  end
end
