require 'json'
require 'optparse'
require 'set'

$options = {
  :urpmf_options => '--media "Core Release"',
  :deps_file => "deps.json",
}

OptionParser.new do |opts|
  opts.banner = "Usage: order.rb [options] <input file>"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    $options[:verbose] = v
  end

  opts.on("--urpmf_options OPTIONS", String, "Set options to urpmf when mapping binaties to sourcerpm") do |f|
    $options[:urpmf_options] = f
  end

  opts.on("--deps FILE", String, "File containing expanded build dependencies of all packages") do |f|
    $options[:deps_file] = f
  end

end.parse!

# Build a map from rpm to src.rpm
def map_binary_to_src
  m={}
  `urpmf #{$options[:urpmf_options]} --qf %sourcerpm:%name :`.each_line{|l|
    s=l.split(/:/)[0].sub(/-[^-]*-[^-]*$/, '')
    b=l.split(/:/)[1].chomp
    m[b]=s
  }
  m
end

def load_file(path)
  File.readlines(path).map(&:chomp)
end

# Load the list of binaries that we want to rebuild, for example the ones linked with a given library
if ARGV.length != 1 then
  puts "Missing input filename containing the list of binary packages to rebuild"
  exit 1
end
todo=load_file(ARGV[0])

bin2src = map_binary_to_src()

if $options[:deps_file].end_with?(".gz") then
  require 'zlib'
  df=File.open($options[:deps_file])
  deps=JSON.parse(Zlib::GzipReader.zcat(df))
  df.close
else
  deps=JSON.load_file($options[:deps_file])
end

basedeps=deps["__CHROOT__"].to_set

remaining={}
todobase=Set[]
todo.each{|p|
  if bin2src[p] then
    if basedeps.include?(p) then
      todobase.add(bin2src[p])
    else
      remaining[p]=bin2src[p]
    end
  else
    puts "WARNING Unknown src for #{p}"
  end
}

if todobase.length > 0 then
  puts "WARNING The following packages are part of the base chroot and will need to be rebuilt first:"
  todobase.to_a.sort.each{|p| puts " #{p}"}
end

wave_number=0
while remaining.length > 0 do
  wave=[]
  blocked={}
  srcs=remaining.values.uniq
  srcs.each{|p|
    blockers=[]
    if deps[p] then
      deps[p].each{|d|
        if bin2src[d] == p then
          puts "WARNING: #{p} has itself installed when being rebuilt"
          next
        end
        if remaining[d] then
          blockers << d
        end
      }
    end
    if blockers.length > 0
      blocked[p] = blockers
    else
      wave << p
    end
  }
  if wave.length > 0 then
    puts
    puts "== Wave #{wave_number}: Set of #{wave.length} package(s) to rebuild =="
    puts wave.join("\n")
    r={}
    remaining.each_pair{|k, v|
      r[k] = v if blocked[v]
    }
    remaining=r
    wave_number=wave_number+1
  end
  if ($options[:verbose] && blocked.length > 0) || wave.length == 0 then
    puts
    puts "Remaining packages can not be rebuilt yet due to dependencies:"
    blocked.each_pair{|k,v|
      puts "#{k}: #{v}"
    }
  end
  if wave.length == 0 then
    puts "No package can be rebuilt anymore."
    exit 1
  end
end

