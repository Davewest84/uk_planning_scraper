$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'uk_planning_scraper'
require 'json'
require 'date'

results = []
errors = []

decided_from = Date.new(2025, 7, 1)
decided_to   = Date.new(2026, 2, 19)
keyword      = "McDonald"

# Only Idox and Northgate are implemented; skip others
authorities = UKPlanningScraper::Authority.all.select { |a| ['idox', 'northgate'].include?(a.system) }

puts "Searching #{authorities.count} authorities for '#{keyword}' decided #{decided_from} to #{decided_to}"
puts "=" * 70
$stdout.flush

authorities.each_with_index do |authority, i|
  puts "\n[#{i + 1}/#{authorities.count}] #{authority.name} (#{authority.system})"
  $stdout.flush

  begin
    apps = authority
      .keywords(keyword)
      .decided_from(decided_from)
      .decided_to(decided_to)
      .scrape(delay: 5)

    if apps.any?
      puts "  -> Found #{apps.count} application(s):"
      apps.each do |app|
        puts "     #{app[:council_reference]} | #{app[:address]}"
        puts "       #{app[:description]}"
      end
      results.concat(apps)
    else
      puts "  -> No results"
    end
  rescue => e
    msg = "#{e.class}: #{e.message}"
    puts "  -> ERROR: #{msg}"
    errors << { authority: authority.name, system: authority.system, error: msg }
  end

  $stdout.flush
end

puts "\n#{"=" * 70}"
puts "COMPLETE"
puts "Total applications found: #{results.count}"
puts "Authorities with errors:  #{errors.count}"

File.write('mcdonalds_results.json', JSON.pretty_generate({
  search: { keyword: keyword, decided_from: decided_from.to_s, decided_to: decided_to.to_s },
  results: results,
  errors: errors
}))

puts "\nFull results saved to mcdonalds_results.json"

# Print a clean summary table
if results.any?
  puts "\n--- RESULTS SUMMARY ---"
  results.each do |app|
    puts "#{app[:authority_name]} | #{app[:council_reference]} | #{app[:date_decision]} | #{app[:description]&.slice(0, 80)}"
  end
end
