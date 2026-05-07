require_relative "test_helper"

require "open3"
require "rbconfig"
require "tmpdir"

class KoansCliTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  CLI = File.join(ROOT, "bin", "koans")

  def run_cli(*args, progress_file: nil)
    env = {}
    env["KOANS_PROGRESS_FILE"] = progress_file if progress_file

    Open3.capture3(env, RbConfig.ruby, CLI, *args, chdir: ROOT)
  end

  def with_progress(contents=nil)
    Dir.mktmpdir do |dir|
      progress_file = File.join(dir, ".path_progress")
      File.write(progress_file, contents) if contents
      yield progress_file
    end
  end

  def assert_success(status, stderr)
    assert status.success?, stderr
  end

  def test_help_shows_commands
    stdout, stderr, status = run_cli("help")

    assert_success(status, stderr)
    assert_match(/Usage: bin\/koans <command>/, stdout)
    assert_match(/watch/, stdout)
    assert_match(/hint/, stdout)
  end

  def test_list_shows_the_path_gates
    with_progress do |progress_file|
      stdout, stderr, status = run_cli("list", progress_file: progress_file)

      assert_success(status, stderr)
      assert_match(/The path currently winds through/, stdout)
      assert_match(/AboutAsserts/, stdout)
      assert_match(%r{koans/about_asserts\.rb}, stdout)
    end
  end

  def test_next_uses_remembered_progress
    with_progress("0") do |progress_file|
      stdout, stderr, status = run_cli("next", progress_file: progress_file)

      assert_success(status, stderr)
      assert_match(/The next stone on the path:/, stdout)
      assert_match(/AboutAsserts#test_assert_truth/, stdout)
      assert_match(%r{koans/about_asserts\.rb:\d+}, stdout)
    end
  end

  def test_hint_uses_existing_koan_comment_without_answer
    with_progress("0") do |progress_file|
      stdout, stderr, status = run_cli("hint", progress_file: progress_file)

      assert_success(status, stderr)
      assert_match(/A whisper from the Master:/, stdout)
      assert_match(/We shall contemplate truth/, stdout)
      assert_match(/No answers\. Only direction\./, stdout)
    end
  end

  def test_reset_requires_a_target
    stdout, stderr, status = run_cli("reset")

    refute status.success?, stdout
    assert_match(/Usage: bin\/koans reset/, stderr)
  end
end
