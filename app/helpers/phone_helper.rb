module PhoneHelper
  # "11987654321" → "(11) 98765-4321"; "1133334444" → "(11) 3333-4444".
  def formatted_phone(digits)
    return if digits.blank?

    number = digits[2..]
    "(#{digits[0, 2]}) #{number[0...-4]}-#{number[-4..]}"
  end
end
