require 'spec_helper'

describe CookerHelper do

  it "Should encode a hex string to Base64" do
    helper.hex_to_base64("01a400a4").should eql("fgGkAKR6")
  end

  it "Should parse normal status response for a cooker" do
    status = helper.parse_status("fg+xAwFQFDABIAAWFgAAAAAA5Xo=")
    expect(status.program_code).to eq 3
    expect(status.status).to eq "cooking"
    expect(status.temperature).to eq 80
    expect(status.cooker_clock_hr).to eq 20
    expect(status.cooker_clock_min).to eq 48
    expect(status.keep_warm_hr).to eq 1
    expect(status.keep_warm_min).to eq 32
    expect(status.cooked_time_hr).to eq 0
    expect(status.cooked_time_min).to eq 22
    expect(status.delay_time_hr).to eq 22
    expect(status.delay_time_min).to eq 0
    expect(status.finished_time_hr).to eq 0
    expect(status.finished_time_min).to eq 0
    expect(status.error).to eq "none"
  end

  it "Should create a proper command for user defined program" do
    prog_array = Array.new
    seed_min = 2
    seed_temp = 10
    for i in 0..8
      prog = CookerUserProgram.new
      prog.step = i+1
      prog.hour = i
      prog.minute = (i*5) + seed_min
      prog.temperature = (i*5) + seed_temp
      prog_array.push(prog)
    end
    expect(helper.user_program_command(prog_array[0..2])).to eq "fg2pAQACCgIBBw8DAgwUAPR6"
    expect(helper.user_program_command(prog_array[3..5])).to eq "fg2pBAMRGQUEFh4GBRsjAWB6"
    expect(helper.user_program_command(prog_array[6..8])).to eq "fg2pBwYgKAgHJS0JCCoyAcx6"
	
	# test reserve byte 7A once
	test_prog = prog_array[0]
	test_prog.temperature = 122
	prog_array[0] = test_prog
	expect(helper.user_program_command(prog_array[0..2])).to eq "fg6pAQACcAoCAQcPAwIMFAFkeg=="
	
	# test reserve byte 7A twice
	test_prog = prog_array[1]
	test_prog.temperature = 122
	prog_array[1] = test_prog
	expect(helper.user_program_command(prog_array[0..2])).to eq "fg+pAQACcAoCAQdwCgMCDBQBz3o="
	
	# test reserve byte 7A thrice
	test_prog = prog_array[2]
	test_prog.temperature = 122
	prog_array[2] = test_prog
	expect(helper.user_program_command(prog_array[0..2])).to eq "fhCpAQACcAoCAQdwCgMCDHAKAjV6"

	# test reserve byte 7E once
	test_prog = prog_array[3]
	test_prog.temperature = 126
	prog_array[3] = test_prog
	expect(helper.user_program_command(prog_array[3..5])).to eq "fg6pBAMRcA4FBBYeBgUbIwHFeg=="
	
	# test reserve byte 7E twice
	test_prog = prog_array[4]
	test_prog.temperature = 126
	prog_array[4] = test_prog
	expect(helper.user_program_command(prog_array[3..5])).to eq "fg+pBAMRcA4FBBZwDgYFGyMCJXo="
	
	# test reserve byte 7E thrice
	test_prog = prog_array[5]
	test_prog.temperature = 126
	prog_array[5] = test_prog
	expect(helper.user_program_command(prog_array[3..5])).to eq "fhCpBAMRcA4FBBZwDgYFG3AOAoB6"
	
	# test reserve byte 70 once
	test_prog = prog_array[6]
	test_prog.temperature = 112
	prog_array[6] = test_prog
	expect(helper.user_program_command(prog_array[6..8])).to eq "fg6pBwYgcAAIByUtCQgqMgIUeg=="
	
	# test reserve byte 70 twice
	test_prog = prog_array[7]
	test_prog.temperature = 112
	prog_array[7] = test_prog
	expect(helper.user_program_command(prog_array[6..8])).to eq "fg+pBwYgcAAIByVwAAkIKjICV3o="
	
	# test reserve byte 70 thrice
	test_prog = prog_array[8]
	test_prog.temperature = 112
	prog_array[8] = test_prog
	expect(helper.user_program_command(prog_array[6..8])).to eq "fhCpBwYgcAAIByVwAAkIKnAAApV6"

	# test reserve bytes 70, 7A, 7E together
	test_prog = prog_array[0]
	test_prog.temperature = 112
	prog_array[0] = test_prog
	test_prog1 = prog_array[1]
	test_prog1.temperature = 122
	prog_array[1] = test_prog1
	test_prog2 = prog_array[2]
	test_prog2.temperature = 126
	prog_array[2] = test_prog2
	expect(helper.user_program_command(prog_array[0..2])).to eq "fhCpAQACcAACAQdwCgMCDHAOAi96"

  end

  it "Should parse status response of a cooker with reserved bytes" do
    # reserves byte: 70
    status = helper.parse_status("fhCxAwFwABQwASAAFhYAAAAAAQV6")
    expect(status.program_code).to eq 3
    expect(status.status).to eq "cooking"
    expect(status.temperature).to eq 112
    expect(status.cooker_clock_hr).to eq 20
    expect(status.cooker_clock_min).to eq 48
    expect(status.keep_warm_hr).to eq 1
    expect(status.keep_warm_min).to eq 32
    expect(status.cooked_time_hr).to eq 0
    expect(status.cooked_time_min).to eq 22
    expect(status.delay_time_hr).to eq 22
    expect(status.delay_time_min).to eq 0
    expect(status.finished_time_hr).to eq 0
    expect(status.finished_time_min).to eq 0
    expect(status.error).to eq "none"

    # reserves byte: 7A
    status = helper.parse_status("fhCxAwFwChQwASAAFhYAAAAAAQ96")
    expect(status.program_code).to eq 3
    expect(status.status).to eq "cooking"
    expect(status.temperature).to eq 122
    expect(status.cooker_clock_hr).to eq 20
    expect(status.cooker_clock_min).to eq 48
    expect(status.keep_warm_hr).to eq 1
    expect(status.keep_warm_min).to eq 32
    expect(status.cooked_time_hr).to eq 0
    expect(status.cooked_time_min).to eq 22
    expect(status.delay_time_hr).to eq 22
    expect(status.delay_time_min).to eq 0
    expect(status.finished_time_hr).to eq 0
    expect(status.finished_time_min).to eq 0
    expect(status.error).to eq "none"

    # reserves byte: 7E
    status = helper.parse_status("fhCxAwFwDhQwASAAFhYAAAAAARN6")
    expect(status.program_code).to eq 3
    expect(status.status).to eq "cooking"
    expect(status.temperature).to eq 126
    expect(status.cooker_clock_hr).to eq 20
    expect(status.cooker_clock_min).to eq 48
    expect(status.keep_warm_hr).to eq 1
    expect(status.keep_warm_min).to eq 32
    expect(status.cooked_time_hr).to eq 0
    expect(status.cooked_time_min).to eq 22
    expect(status.delay_time_hr).to eq 22
    expect(status.delay_time_min).to eq 0
    expect(status.finished_time_hr).to eq 0
    expect(status.finished_time_min).to eq 0
    expect(status.error).to eq "none"
  end


end
