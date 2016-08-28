KURO_MARU_NUM = 5
SHIRO_MARU_NUM = 5
MARU_NUM = KURO_MARU_NUM + SHIRO_MARU_NUM
KURO_SANKAKU_NUM = 5
SHIRO_SANKAKU_NUM = 5
SANKAKU_NUM = KURO_SANKAKU_NUM + SHIRO_SANKAKU_NUM
ALL_NUM = MARU_NUM + SANKAKU_NUM
KURO_MARU_ARY = (0...KURO_MARU_NUM).to_a
SHIRO_MARU_ARY = (KURO_MARU_NUM...MARU_NUM).to_a
KURO_SANKAKU_ARY = (MARU_NUM...MARU_NUM + KURO_SANKAKU_NUM).to_a
SHIRO_SANKAKU_ARY = (MARU_NUM + KURO_SANKAKU_NUM...ALL_NUM).to_a
MARU_MAX_ACIF = ((25 * 3.5) / MARU_NUM).ceil
SANKAKU_MAX_ACIF = ((25 * 3.6) / SANKAKU_NUM).ceil

def init_schedule
  s = []
  KURO_MARU_NUM.times do
    s << []
  end
  SHIRO_MARU_NUM.times do
    s << []
  end
  KURO_SANKAKU_NUM.times do
    s << []
  end
  SHIRO_SANKAKU_NUM.times do
    s << []
  end
  s
end

def validate_today(schedule, date, try_times)
  # ACIF が重複していないか確認
  count = 0
  schedule.each do |sche|
    count += 1 unless sche[date].nil?
  end
  return false if count != 7

  # 1日目は前日を気にしなくても良い
  return true if date == 0

  # できれば満たしたい条件 (条件をだんだんゆるくしていく)
  false_flg = false
  if try_times > 5000
    # 緩い条件
    # 1. 前日にI, 当日にA の連続はダメ
    schedule.each do |sche|
      false_flg = true if sche[date - 1] == 'I' && sche[date] == 'A'
    end
  elsif try_times > 1000
    # まぁまぁ条件
    # 1. 前日にI, 当日にA の連続はダメ
    schedule.each do |sche|
      false_flg = true if sche[date - 1] == 'I' && sche[date] == 'A'
    end
    # 2. 3日連続で入っていた場合はダメ
    if date > 2
      schedule.each do |sche|
        false_flg = true if !sche[date - 2].nil? && \
                            !sche[date - 1].nil? && \
                            !sche[date].nil?
      end
    end
  else
    # キツイ条件
    # 1. 前日も入っていた場合はダメ
    schedule.each do |sche|
      false_flg = true if !sche[date - 1].nil? && !sche[date].nil?
    end
  end
  return false if false_flg
  return false unless validate_person(schedule)
  true
end

def validate_person(schedule)
  flg = true
  schedule.each_with_index do |person, id|
    types = person.compact
    # 一人の記号上限回数を超えたらだめ
    if id < MARU_NUM
      flg = false if types.size > MARU_MAX_ACIF
    else
      flg = false if types.size > SANKAKU_MAX_ACIF
    end
    type_count = Hash.new(0)
    types.each do |type|
      type_count[type] += 1
    end
    # 同じ種類が3回まで
    flg = false if (type_count.values.max || 0) > 3
    # F が2回まで
    flg = false if (type_count['F'] || 0) > 2
  end
  flg
end

def print_schedule(schedule)
  print '曜日,'
  5.times do |i|
    print "#{i + 1}月,"
    print "#{i + 1}火,"
    print "#{i + 1}水,"
    print "#{i + 1}木,"
    print "#{i + 1}金,"
    print "#{i + 1}土,"
    print "#{i + 1}日,"
  end
  print "\n"
  schedule.each_with_index do |k, i|
    if i < KURO_MARU_NUM
      print "●#{i + 1},"
    elsif i < MARU_NUM
      print "○#{i + 1 - KURO_MARU_NUM},"
    elsif i < MARU_NUM + KURO_SANKAKU_NUM
      print "▲#{i + 1 - MARU_NUM},"
    else
      print "△#{i + 1 - (MARU_NUM + KURO_SANKAKU_NUM)},"
    end
    k.each do |s|
      print "#{s},"
    end
    print "\n"
  end
end

# ロジック
schedule = []
loop do
  schedule = init_schedule
  retry_flg = false
  all_f_flg = false
  first_f_pool = (0...ALL_NUM).to_a

  # 5週間(平日25日+休日8日)分を計算する
  33.times do |date|
    next if date % 7 == 5 || date % 7 == 6
    try_times = 0
    loop do
      try_times += 1
      # その日のスケジュールをクリア
      ALL_NUM.times do |id|
        schedule[id][date] = nil
      end
      # MARU の中から A, C, I の3人を選ぶ
      maru_acis = (KURO_MARU_ARY + SHIRO_MARU_ARY).sample(3)
      maru_acis.each_with_index do |id, i|
        type = %w(A C I)[i]
        schedule[id][date] = type

        # 同じ色の SANKAKU から1人選ぶ
        if KURO_MARU_ARY.include?(id)
          pair_id = KURO_SANKAKU_ARY.sample(1).first
          schedule[pair_id][date] = type
        else
          pair_id = SHIRO_SANKAKU_ARY.sample(1).first
          schedule[pair_id][date] = type
        end
      end
      # F を選ぶ
      pool = first_f_pool.dup
      if all_f_flg
        # 適当に選ぶ
        id = (0...ALL_NUM).to_a.sample(1).first
        schedule[id][date] = 'F'
      else
        # F を持っていない人から選ぶ
        id = pool.sample(1).first
        pool.delete(id)
        schedule[id][date] = 'F'
      end
      if validate_today(schedule, date, try_times)
        first_f_pool = pool
        all_f_flg = true if first_f_pool.size == 0
        break
      end

      # 何回計算しても無理だったら全部やりなおす
      if try_times > 10_000
        retry_flg = true
        p "Try Again: date at #{date}"
      end
      break if retry_flg
    end
    break if retry_flg
  end
  break unless retry_flg
end

print_schedule(schedule)
