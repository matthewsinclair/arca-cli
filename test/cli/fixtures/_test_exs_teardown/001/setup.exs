# Create a marker file that teardown should clean up
tmp_dir = System.tmp_dir!()
marker_file = Path.join(tmp_dir, "arca_test_marker_#{:rand.uniform(1_000_000)}.tmp")
File.write!(marker_file, "cleanup marker")

# Return bindings including confirmation that setup ran
%{
  marker_file: marker_file,
  setup_status: "created"
}
