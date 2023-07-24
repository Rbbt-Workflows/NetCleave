require 'rbbt-util'
require 'rbbt/workflow'
require 'rbbt/tsv/csv'

Misc.add_libdir if __FILE__ == $0

#require 'rbbt/sources/NetCleave'

module NetCleave
  extend Workflow
  extend Resource

  # Add binary, decompress models
  Rbbt.claim Rbbt.software.opt.NetCleave, :install do
    {:git => "https://github.com/BSC-CNS-EAPM/NetCleave.git", :commands => "chmod +x $OPT_DIR/NetCleave/NetCleave.py"}
  end

  CMD.tool "NetCleave.py", Rbbt.software.opt.NetCleave

  input :fasta, :text, "FASTA file", nil, :required => true
  task :predict_fasta => :tsv do |fasta|
    fasta_file = file('input.fasta')
    output = file('ouput')

    Open.write(fasta_file, fasta)

    Misc.in_dir files_dir do
      CMD.cmd(Rbbt.software.opt.NetCleave["NetCleave.py"].produce.find, "--predict #{fasta_file} --pred_input 1")
    end

    file = Dir.glob(File.join(files_dir, 'output/*.csv')).first

    TSV.open(file, :sep => ',', :header_hash => '')
  end

  input :uniprot_csv, :text, "CSV file with paired peptides and UniProt ids", nil, :required => true
  task :predict_uniprot => :tsv do |csv|
    input_csv = file('input.csv')
    output = file('ouput')

    csv = Open.read(csv) if Misc.is_filename?(csv)

    str = "epitope,uniprot_id\n"
    TSV.traverse StringIO.new(csv), :type => :line, :into => str do |line|
      next if line.downcase.include? 'uniprot'
      peptide, uniprot = line.split(",")
      [peptide, uniprot] * "," + "\n"
    end


    Open.write(input_csv, str)

    Misc.in_dir files_dir do
      CMD.cmd(Rbbt.software.opt.NetCleave["NetCleave.py"].produce.find, "--predict #{input_csv} --pred_input 2")
    end

    file = Dir.glob(File.join(files_dir, 'output/*.csv')).first
    tmp_file = file('tmp.tsv')
    Open.write(tmp_file, 'ID' + Open.read(file))
    tsv = TSV.open(tmp_file, :sep => ',', :header_hash => '')
    corrected_fields = tsv.fields
    corrected_fields[-1] = "netcleave"
    tsv.fields = corrected_fields
    tsv
  end

  input :custom_csv, :text, "CSV file with paired peptides, custom protein sequence and protein name", nil, :required => true
  task :predict_custom => :tsv do |csv|
    input_csv = file('input.csv')
    output = file('ouput')

    Open.write(input_csv, csv)

    Misc.in_dir files_dir do
      CMD.cmd(Rbbt.software.opt.NetCleave["NetCleave.py"].produce.find, "--predict #{input_csv} --pred_input 3")
    end

    file = Dir.glob(File.join(files_dir, 'output/*.csv')).first
    tmp_file = file('tmp.tsv')
    Open.write(tmp_file, 'ID' + Open.read(file))
    tsv = TSV.open(tmp_file, :sep => ',', :header_hash => '')
    corrected_fields = tsv.fields
    corrected_fields[-1] = "netcleave"
    tsv.fields = corrected_fields
    tsv
  end

end

#require 'NetCleave/tasks/basic.rb'

#require 'rbbt/knowledge_base/NetCleave'
#require 'rbbt/entity/NetCleave'

