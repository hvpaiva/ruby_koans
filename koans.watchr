def run_koans
  system 'clear' if STDOUT.tty?
  system 'ruby bin/koans walk'
end

watch(%r{^koans/.*\.(rb|txt)$}) do
  run_koans
end

run_koans
