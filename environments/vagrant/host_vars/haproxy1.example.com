---
nomad_node_role: "client"
nomad_options:
  driver.raw_exec.enable: 1
nomad_node_class: "haproxy"
