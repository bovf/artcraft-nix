//! The actual source detector and the package's private test namespace.
#![allow(dead_code)]

#[path = "@memoryDetector@"]
mod memory;

#[test]
fn real_constraints_are_readable_without_child_capabilities() {
    let snapshot = memory::current();
    assert!(!snapshot.constraint_unreadable, "{snapshot:?}");
    assert!(
        snapshot.available_ram.is_some_and(|bytes| bytes > 0),
        "{snapshot:?}"
    );
    let status = std::fs::read_to_string("/proc/self/status").unwrap();
    for key in ["CapEff:", "CapBnd:", "CapAmb:"] {
        let line = status.lines().find(|line| line.starts_with(key)).unwrap();
        assert_eq!(line.split_whitespace().nth(1), Some("0000000000000000"));
    }
    assert!(
        status
            .lines()
            .any(|line| line.starts_with("NoNewPrivs:")
                && line.split_whitespace().nth(1) == Some("1"))
    );
}
