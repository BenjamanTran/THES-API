# frozen_string_literal: true

class GeoCalculator
  EARTH_RADIUS_KM = 6371

  def self.distance_km(lat1, lng1, lat2, lng2)
    rad = Math::PI / 180
    dlat = (lat2 - lat1) * rad
    dlng = (lng2 - lng1) * rad

    a = haversine_a(lat1 * rad, lat2 * rad, dlat, dlng)
    (EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).round(2)
  end

  def self.haversine_a(rlat1, rlat2, dlat, dlng)
    sin_dlat = Math.sin(dlat / 2)
    sin_dlng = Math.sin(dlng / 2)
    (sin_dlat**2) + (Math.cos(rlat1) * Math.cos(rlat2) * (sin_dlng**2))
  end

  private_class_method :haversine_a
end
