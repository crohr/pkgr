class EnvValue < String
  def quote(type=:double, count=nil)
    if Integer === type
      tmp   = count
      count = type
      type  = tmp || :mixed
    else
      count ||= 1
    end

    type = type.to_s unless Integer===type

    case type
    when "'", 'single', 's', 1
      f = "'" * count
      b = f
    when '"', 'double', 'd', 2
      f = '"' * count
      b = f
    when '`', 'back', 'b', -1
      f = '`' * count
      b = f
    when "`'", 'bracket', 'sb'
      f = "`" * count
      b = "'" * count
    when "'\"", 'mixed', "m", Integer
      c = (count.to_f / 2).to_i
      f = '"' * c
      b = f
      if count % 2 != 0
        f = "'" + f
        b = b + "'"
      end
    else
      raise ArgumentError, "unrecognized quote type -- #{type}"
    end
    "#{f}#{self}#{b}"
  end

  def unquote
    s = self.dup

    case self[0,1]
    when "'", '"', '`'
      s[0] = ''
    end

    case self[-1,1]
    when "'", '"', '`'
      s[-1] = ''
    end

    return s
  end
end
