require 'ostruct'

module Pkgr
  class Config < OpenStruct
    def sesame
      binding
    end

    def home
      "/opt/#{name}"
    end

    def user
      @table[:user] || "root"
    end

    def group
      @table[:group] || user
    end

    def valid?
      @errors = []
      @errors.push("name can't be blank") if name.nil? || name.empty?
      @errors.push("version can't be blank") if version.nil? || version.empty?
      @errors.push("iteration can't be blank") if iteration.nil? || iteration.empty?
      @errors.push("user can't be blank") if user.nil? || user.empty?
      @errors.push("group can't be blank") if group.nil? || group.empty?
      @errors.empty?
    end

    def errors
      @errors ||= []
    end
  end
end
