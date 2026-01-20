defmodule DocSpec.Test.SnapshotTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Mimic
  import DocSpec.Test.Snapshot

  describe "assert_snapshot/3" do
    test "saves the actual value to a file" do
      snapshot_name = "SnapshotTest/assert_snapshot/saves_to_file"
      value = "some expected value"
      snapshot_name |> snapshot_path(:expected, :exs) |> Path.dirname() |> File.mkdir_p!()
      snapshot_name |> snapshot_path(:expected, :exs) |> File.write(inspect(value, pretty: true))

      assert_snapshot(value, snapshot_name)

      actual_value = snapshot_name |> snapshot_path(:actual, :exs) |> File.read!()
      assert actual_value == inspect(value, pretty: true)
    end

    test "also saves the expected value to a file with option :save_expected" do
      snapshot_name = "SnapshotTest/assert_snapshot/saves_expected_to_file"
      value = "some expected value"

      expect(File, :mkdir_p!, 2, fn path ->
        assert path == snapshot_name |> snapshot_path(:expected, :exs) |> Path.dirname()
      end)

      expect(File, :write!, 1, fn path, content ->
        assert path == snapshot_name |> snapshot_path(:actual, :exs)
        assert content == inspect(value, pretty: true)
      end)

      expect(File, :write!, 1, fn path, content ->
        assert path == snapshot_name |> snapshot_path(:expected, :exs)
        assert content == inspect(value, pretty: true)
      end)

      expect(File, :read!, 1, fn path ->
        assert path == snapshot_name |> snapshot_path(:expected, :exs)
        inspect(value, pretty: true, limit: :inifinity)
      end)

      assert_snapshot(value, snapshot_name, save_expected: true)
    end

    test "successfully asserts when the actual value matches the expected value" do
      snapshot_name = "SnapshotTest/assert_snapshot/expected_matches_actual"
      value = "expected value"
      snapshot_name |> snapshot_path(:expected, :exs) |> Path.dirname() |> File.mkdir_p!()
      snapshot_name |> snapshot_path(:expected, :exs) |> File.write(inspect(value, pretty: true))

      assert_snapshot(value, snapshot_name)
    end

    test "successfully asserts when the actual value matches the expected value (HTML)" do
      snapshot_name = "SnapshotTest/assert_snapshot/expected_matches_actual_html"
      value = "<b>expected value</b>"
      snapshot_name |> snapshot_path(:expected, :html) |> Path.dirname() |> File.mkdir_p!()
      snapshot_name |> snapshot_path(:expected, :html) |> File.write(value)

      assert_snapshot(value, snapshot_name, format: :html)
    end

    test "raises an assertion error when the actual value does not match the expected value" do
      snapshot_name = "SnapshotTest/assert_snapshot/expected_does_not_match_actual"
      snapshot_name |> snapshot_path(:expected, :json) |> Path.dirname() |> File.mkdir_p!()

      snapshot_name
      |> snapshot_path(:expected, :json)
      |> File.write(~s'{"foo": "bar", "lorem": "ipsum"}')

      try do
        assert_snapshot(%{abc: 123, xyz: "123"}, snapshot_name, format: :json)
        flunk("Expected an error to be raised")
      rescue
        error in ExUnit.AssertionError ->
          assert """
                 Snapshot test on SnapshotTest/assert_snapshot/expected_does_not_match_actual failed: actual value does not match the expected value. Please see the difference below.

                 If the actual value is correct, save it as the snapshot's expected value by running the following command:

                 $ cp 'test/snapshots/SnapshotTest/assert_snapshot/expected_does_not_match_actual/actual.json' 'test/snapshots/SnapshotTest/assert_snapshot/expected_does_not_match_actual/expected.json'

                 Or use the `:save_expected` option on `assert_snapshot/3` to overwrite the expected value.
                 """ == error.message

        error ->
          reraise error, __STACKTRACE__
      end
    end

    test "raises an assertion error when the expected value is not found" do
      snapshot_name = "SnapshotTest/assert_snapshot/expected_not_found"

      try do
        assert_snapshot("actual value", snapshot_name, format: :json)
        flunk("Expected an error to be raised")
      rescue
        error in ExUnit.AssertionError ->
          assert """
                 No expected value is saved for snapshot "SnapshotTest/assert_snapshot/expected_not_found".

                 If the actual value is correct, save it as the snapshot's expected value by running the following command:

                 $ cp 'test/snapshots/SnapshotTest/assert_snapshot/expected_not_found/actual.json' 'test/snapshots/SnapshotTest/assert_snapshot/expected_not_found/expected.json'

                 Or use the `:save_expected` option on `assert_snapshot/3` to overwrite the expected value.

                 """ == error.message

        error ->
          reraise error, __STACKTRACE__
      end
    end

    test "raises an error when an error occurs while loading the snapshot's expected value" do
      snapshot_name = "SnapshotTest/assert_snapshot/expected_has_error"
      snapshot_name |> snapshot_path(:expected, :json) |> Path.dirname() |> File.mkdir_p!()

      expect(File, :read!, 1, fn path ->
        assert path == snapshot_name |> snapshot_path(:expected, :json)
        raise File.Error, path: "test", reason: :fake
      end)

      assert_raise File.Error, "could not  \"test\": unknown POSIX error: fake", fn ->
        assert_snapshot(%{}, snapshot_name, format: :json)
      end
    end
  end
end
