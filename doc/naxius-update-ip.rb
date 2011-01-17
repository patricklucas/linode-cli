#!/usr/bin/env ruby

require 'linode'

api_key = 'rxAbs8sQ4kZ0HVzC1BDDgIGBKNuuhvGckoIIkgUCnuLiHiCymSrwmKYuCXQxLaMf'

domain = 'patricklucas.net'
hostname = 'naxius'
newip = ENV['SSH_CLIENT'].split[0]

def validate_ip(ip)
    octets = ip.split('.')

    if octets.size != 4
        raise 'Invalid IP'
    end

    octets.each_with_index do |octet, i|
        int = Integer(octet)

        if [0, 3].include? i
            if int <= 0 or int >= 256
                raise 'Invalid IP'
            end
        else
            if int < 0 or int >= 256
                raise 'Invalid IP'
            end
        end
    end

    return true
end

validate_ip(newip)

l = Linode.new(:api_key => api_key)

domainid = (l.domain.list.detect {|res| res.domain == domain}).domainid

record = l.domain.resource.list(:domainid => domainid).detect {|res| res.name == hostname}

if not record
    raise 'Hostname does not exist'
end

if record.type.casecmp('A') != 0
    puts record
    raise 'Hostname is not an A record'
end

l.domain.resource.update(
    :domainid => domainid,
    :resourceid => record.resourceid,
    :target => newip
)
