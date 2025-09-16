require 'json'
require 'set'

def load_deps(path)
  File.readlines(path).map{|d| d.sub(/-[^-]*-[^-]*$/, '')}
end

basedeps=nil
deps = {}
i=0
Dir.glob("#{ARGV[0]}/log/*/rpm_qa.*.0.*.log"){|f|
  d=load_deps(f).to_set
  s=f.split(/\//)[6].sub(/-[^-]*-[^-]*$/, '')
  print "\rProcessing package #{i}"
  i+=1
  if basedeps==nil then
    # If this is the first package, start the list of chroot things with its deps
    basedeps=d
  else
    # If this is not the first package, remove deps it does not have from basedeps
    basedeps=basedeps&d
    # There was a corrupted file once
    if basedeps.length == 0 then
      puts "ERROR: #{f} is empty"
      exit
    end
  end
  deps[s]=d
}
puts "\rProcessed #{i} packages"

# Filter out base deps to shrink the size of the output
deps.each_key{|p|
  deps[p]=(deps[p]-basedeps).to_a.sort
}
deps["__CHROOT__"] = basedeps.to_a.sort


File.open("deps.json", 'w') { |file| file.write(JSON.pretty_generate(deps)) }


