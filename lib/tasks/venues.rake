# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

namespace :venues do
  desc 'Import badminton venues from Mapbox Search Box API for HCM and HN'
  task import_from_mapbox: :environment do
    token = ENV.fetch('MAPBOX_ACCESS_TOKEN') do
      ENV.fetch('NEXT_PUBLIC_MAPBOX_TOKEN') { abort 'Set MAPBOX_ACCESS_TOKEN or NEXT_PUBLIC_MAPBOX_TOKEN env var' }
    end

    regions = [
      { name: 'HCM', lat_min: 10.68, lat_max: 10.90, lng_min: 106.58, lng_max: 106.84 },
      { name: 'HN',  lat_min: 20.94, lat_max: 21.10, lng_min: 105.72, lng_max: 105.95 }
    ]

    queries = ['sân cầu lông', 'badminton', 'cầu lông', 'CLB cầu lông']
    step = 0.015 # ~1.5km per grid cell

    total_created = 0
    total_skipped = 0

    regions.each do |region|
      puts "\n=== #{region[:name]} ==="

      zones = generate_grid(region[:lat_min], region[:lat_max], region[:lng_min], region[:lng_max], step)
      puts "  Grid: #{zones.size} cells"

      zones.each_with_index do |zone, zi|
        queries.each do |q|
          results = mapbox_search(token, q, zone[:proximity], zone[:bbox])

          results.each do |feat|
          props = feat['properties'] || {}
          geo = feat['geometry'] || {}
          coords = geo['coordinates'] || []

          mapbox_id = props['mapbox_id']
          next unless mapbox_id

          if Venue.exists?(mapbox_id: mapbox_id)
            total_skipped += 1
            next
          end

          name = props['name'] || props['name_preferred'] || 'Unknown'
          address = props['full_address'] || props['address'] || ''
          lng, lat = coords

          next if shop_name?(name)

          context = props['context'] || {}
          district = extract_quan(address) ||
                     context.dig('locality', 'name') ||
                     context.dig('place', 'name')
          ward = context.dig('district', 'name') ||
                 context.dig('neighborhood', 'name')
          full_district = [district, ward].compact.reject(&:empty?).join(', ')

          city = detect_city(address, region[:name])

          Venue.create!(
            name: name,
            address: address.presence,
            city: city,
            district: full_district.presence,
            lat: lat,
            lng: lng,
            mapbox_id: mapbox_id,
            verified: true
          )

          total_created += 1
          print "\r  Created: #{total_created} | Skipped: #{total_skipped}    "
        rescue ActiveRecord::RecordInvalid
          # skip invalid
        end
      end
        sleep 0.1
      end
      puts ""
    end

    puts "\n=== Done ==="
    puts "Created: #{total_created}"
    puts "Skipped (duplicates): #{total_skipped}"
    puts "Total venues in DB: #{Venue.count}"
  end
end

def generate_grid(lat_min, lat_max, lng_min, lng_max, step)
  zones = []
  lat = lat_min
  while lat < lat_max
    lng = lng_min
    while lng < lng_max
      center_lat = lat + step / 2.0
      center_lng = lng + step / 2.0
      zones << {
        proximity: "#{center_lng.round(4)},#{center_lat.round(4)}",
        bbox: "#{lng.round(4)},#{lat.round(4)},#{(lng + step).round(4)},#{(lat + step).round(4)}"
      }
      lng += step
    end
    lat += step
  end
  zones
end

def mapbox_search(token, query, proximity, bbox)
  base = 'https://api.mapbox.com/search/searchbox/v1/forward'
  params = {
    q: query,
    access_token: token,
    proximity: proximity,
    bbox: bbox,
    types: 'poi',
    language: 'vi',
    limit: 10,
    country: 'VN'
  }

  uri = URI(base)
  uri.query = URI.encode_www_form(params)

  response = Net::HTTP.get_response(uri)

  unless response.is_a?(Net::HTTPSuccess)
    puts "    ! API error: #{response.code} #{response.message}"
    puts "    ! Body: #{response.body[0..300]}" if response.body
    return []
  end

  data = JSON.parse(response.body)
  data['features'] || []
rescue StandardError => e
  puts "    ! Request failed: #{e.message}"
  []
end

def detect_city(address, fallback)
  return 'HCM' if address.match?(/h[oồ]\s*ch[ií]\s*minh|tp\.?\s*hcm|hcm|sài gòn/i)
  return 'HN' if address.match?(/h[aà]\s*n[oộ]i/i)

  fallback
end

def extract_quan(address)
  match = address.match(/(?:qu[aậ]n|q\.?)\s*([^,]+)/i)
  return match[1].strip if match

  match = address.match(/(thành phố thủ đức|tp\.?\s*thủ đức)/i)
  return 'Thủ Đức' if match

  nil
end

SHOP_KEYWORDS = %w[
  shop cửa\ hàng văn\ phòng vợt store bán phân\ phối
  đại\ lý agency outlet retail phụ\ kiện
].freeze

def shop_name?(name)
  down = name.downcase
  SHOP_KEYWORDS.any? { |kw| down.include?(kw) }
end
