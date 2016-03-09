# source docker helpers
. util/docker.sh

echo_lines() {
  for (( i=0; i < ${#lines[*]}; i++ ))
  do
    echo ${lines[$i]}
  done
}

@test "Start Old Container" {
  start_container "simple-single-old" "192.168.0.2"
}

@test "Configure Old Container" {
  run run_hook "simple-single-old" "default-configure" "$(payload default/configure-production)"

  [ "$status" -eq 0 ] 
}

@test "Start Old PostgreSQL" {
  run run_hook "simple-single-old" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-old bash -c "ps aux | grep [p]ostgres"
  [ "$status" -eq 0 ]
  until docker exec "simple-single-old" bash -c "nc 192.168.0.2 5432 < /dev/null"
  do
    sleep 1
  done
}

@test "Insert Old PostgreSQL Data" {
  run docker exec "simple-single-old" bash -c "/data/bin/psql -U gonano -t -c 'CREATE TABLE test_table (id SERIAL PRIMARY KEY, value bigint);'"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/psql -U gonano -t -c 'INSERT INTO test_table VALUES (1, 1);'"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/psql -U gonano -t -c 'SELECT * FROM test_table;'"
  echo_lines
  [ "${lines[0]}" = "  1 |     1" ]
  [ "$status" -eq 0 ]
}

@test "Start New Container" {
  start_container "simple-single-new" "192.168.0.3"
}

@test "Configure New Container" {
  run run_hook "simple-single-new" "default-configure" "$(payload default/configure-production)"
  [ "$status" -eq 0 ] 
}

@test "Start New PostgreSQL" {
  run run_hook "simple-single-new" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [p]ostgres"
  [ "$status" -eq 0 ] 
}

@test "Stop New PostgreSQL" {
  run run_hook "simple-single-new" "default-stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-new" bash -c "ps aux | grep [p]ostgres"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [p]ostgres"
  [ "$status" -eq 1 ] 
}

@test "Start New SSHD" {
  # start ssh server
  run run_hook "simple-single-new" "default-start_sshd" "$(payload default/start_sshd)"
  echo_lines
  [ "$status" -eq 0 ]
  until docker exec "simple-single-new" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Pre-Export Old PostgreSQL" {
  run run_hook "simple-single-old" "default-single-pre_export" "$(payload default/single/pre_export)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Update Old PostgreSQL Data" {
  run docker exec "simple-single-old" bash -c "/data/bin/psql -U gonano -t -c 'UPDATE test_table SET value = 2 WHERE id = 1;'"
  echo_lines
  [ "$status" -eq 0 ]
  run docker exec "simple-single-old" bash -c "/data/bin/psql -U gonano -t -c 'SELECT * FROM test_table;'"
  echo_lines
  [ "${lines[0]}" = "  1 |     2" ]
  [ "$status" -eq 0 ]
}

@test "Stop Old PostgreSQL" {
  run run_hook "simple-single-old" "default-stop" "$(payload default/stop)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-old" bash -c "ps aux | grep [p]ostgres"
  do
    sleep 1
  done
  # Verify
  run docker exec simple-single-old bash -c "ps aux | grep [p]ostgres"
  [ "$status" -eq 1 ] 
}

@test "Export Old PostgreSQL" {
  run run_hook "simple-single-old" "default-single-export" "$(payload default/single/export)"
  echo_lines
  [ "$status" -eq 0 ]
}

@test "Stop New SSHD" {
  # stop ssh server
  run run_hook "simple-single-new" "default-stop_sshd" "$(payload default/stop_sshd)"
  [ "$status" -eq 0 ]
  while docker exec "simple-single-new" bash -c "ps aux | grep [s]shd"
  do
    sleep 1
  done
}

@test "Restart New PostgreSQL" {
  run run_hook "simple-single-new" "default-start" "$(payload default/start)"
  [ "$status" -eq 0 ]
  # Verify
  run docker exec simple-single-new bash -c "ps aux | grep [p]ostgres"
  [ "$status" -eq 0 ]
  until docker exec "simple-single-new" bash -c "nc 192.168.0.3 5432 < /dev/null"
  do
    sleep 1
  done
}

@test "Verify New PostgreSQL Data" {
  run docker exec "simple-single-new" bash -c "/data/bin/psql -U gonano -t -c 'SELECT * FROM test_table;'"
  echo_lines
  [ "${lines[0]}" = "  1 |     2" ]
  [ "$status" -eq 0 ]
}

@test "Stop Old Container" {
  stop_container "simple-single-old"
}

@test "Stop New Container" {
  stop_container "simple-single-new"
}