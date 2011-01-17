#!/usr/bin/env ruby

require 'linode'
require 'optparse'

ENVS = [
    :dns
]

API_KEY = 'rxAbs8sQ4kZ0HVzC1BDDgIGBKNuuhvGckoIIkgUCnuLiHiCymSrwmKYuCXQxLaMf'

class LinodeEnv
end

class DNS < LinodeEnv
    Commands = [
        :show
    ]

    def go(params)
        cmd = params[0].to_sym

        case cmd
        when :show
            DNSShow.new.go params[1, params.length - 1]
        end
    end
end

class DNSShow < LinodeEnv
    RecordTypes = [
        :a,
        :aaaa,
        :cname
    ]

    def go(params)
        if RecordTypes.include? params[0].to_sym
            type = params[0].to_sym
            domain = params[1]
        else
            type = :all
            domain = params[0]
        end

        if type == :all
            return
        end

        case type
        when :a
            fmt = lambda {|r| "A #{r.name}"}
        when :aaaa
            fmt = lambda {|r| "AAAA #{r.name}"}
        when :cname
            fmt = lambda {|r| "CNAME #{r.name}"}
        when :mx
            fmt = lambda {|r| "MX #{r.target}"}
        end

        domainid = ($l.domain.list.detect {|res| res.domain == domain}).domainid

        records = $l.domain.resource.list(:domainid => domainid).select {|d| d.type.downcase.to_sym == type}

        records.each do |r|
            puts fmt.call r
        end
    end
end

def do_summary
    puts "linode"
end

if ARGV.size == 0
    do_summary
    exit
end

env = ARGV[0].to_sym

unless ENVS.include? env
    puts "Not valid env"
    exit 1
end

$l = Linode.new(:api_key => API_KEY)

if env == :dns
    DNS.new.go ARGV[1, ARGV.length - 1]
end
