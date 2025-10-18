defmodule KachingkoApi.Statements.TransactionCategorizer do
  @moduledoc """
  Categorizes transactions based on description patterns.
  """

  defp categories do
    [
      {
        "Food & Dining",
        [
          {"Coffee Shops",
           ~r/\b(UCC|STARBUCKS|COFFEE\s?BEAN|CBTL|TIM\s?HORTONS|SEATTLE'?S\s?BEST|FIGARO|BO'S\s?COFFEE|ANGKAN|YARDSTICK|%ARABICA|DAILY\s?BREW|SEE\s?THE\s?WORLD|BUT\s?FIRST\s?COFFEE|BFC)\b/i},
          {"Coffee Shops", ~r/(UCC)/i},
          {"Bakeries / Pastry Shops",
           ~r/\b(CONTIS|RED\s?RIBBON|PAN\s?DE\s?MANILA|PURPLE\s?OVEN|FRENCH\s?BAKER|GOLDILOCKS)\b/i},
          {"Coffee Shops and Donuts", ~r/\b(DONUTS)\b/i},
          {"Fast Food",
           ~r/\b(MCDO|MCDONALD'?S?|GADC|JOLLIBEE|KFC|CHOWKING|GREENWICH|BURGER\s?KING|WENDY'?S|BONCHON|PIZZA\s?HUT|SHAKEYS|MODERN\s?SHANG|YELLOW\s?CAB|POPEYES|TACO\s?BELL)\b/i},
          {"Casual Dining",
           ~r/\b(CLASSIC\s?SAVORY|CAFE\s?MED|JUST\s?THAI|PANCAKE\s?HOUSE|NONOS|NONNAS|GINOS\s?BRICK|RHM\s?IHAW\-IHAW|GERRYS\s?GRILL|FAT\s?FOOK|GREEN\s?WHICH|PHO\s?SAIGON|PANDA\s?EXPRESS|HAWKER\s?CHAN|TIM\s?HO\s?WAN|CAFE\s?ADRIATICO|NORTH\s?PARK|MAMA\s?LOUS|PANCAKE\s?HSE|MARY\s?GRACE|KENNY\s?ROGERS|MANGAN|YELLOW\s?CAB|MANAM|MESA|ARMY\s?NAVY|ITALIANNIS|ZARKS|MAXS|MANG\s?BOYS|RBQ\s?FOOD\s?SPECIALIST|BUDDYS|YABU|MAMOU|JTS\s?MANUKAN|DENNYS|BUFFALO\s?WINGS|TGI\s?FRIDAYS|CIBO|WILD\s?FLOUR|DIN\s?TAI\s?FUNG)\b/i},
          {"Casual Dining", ~r/(GREENWCH)/i},
          {"Buffet",
           ~r/\b(VIKINGS|NIU|BUFFET\s?101|DADS|YAKIMIX|SAMGYUPSAL|ROMANTIC\s?BABOY|SEOUL\s?GYUPSIK)\b/i},
          {"Japanese",
           ~r/\b(NAGI\s?IZAKAYA|COCO\s?ICHIBANYA|DOHJIMA|PEPPER\s?LUNCH|YAYOI|RAMEN|MARUGAME|BOTEJYU|WATAMI|MENYA\s?KOKORO)\b/i},
          {"Korean", ~r/\b(BULGOGI)\b/i},
          {"Dessert / Frozen Yogurt", ~r/\b(LLAOLLAO)\b/i},
          {"Lechon Specialty", ~r/\b(LLAOLLAO)\b/i},
          {"Matcha Dessert Shop", ~r/\b(TSUJIRI)\b/i},
          {"Fast Food / Sandwich Shop", ~r/(SUBWAY)/i},
          {"Food Service Management / Meal Provider", ~r/\b(KC\s?FMS)\b/i}
        ]
      },
      {
        "Health & Pharmacy",
        [
          {"Pharmacies",
           ~r/\b(MERCURY\s?DRUG|MAXS|WATSONS|SOUTH\s?STAR\s?DRUG|ROSE\s?PHARMACY|THE\s?GENERICS|MEDEXPRESS)\b/i},
          {"Pharmacies", ~r/(MERCURY\s?DRUG)/i},
          {"Health Food & Supplements", ~r/\b(HEALTHY\s?OPTIONS|GNC)\b/i}
        ]
      },
      {
        "Credit Card",
        [
          {"Cash Rebate", ~r/\b(CASH\s?REBATE)\b/i},
          {"Payment", ~r/^PAYMENT$/i}
        ]
      },
      {
        "Health & Wellness",
        [
          {"Spa & Massage Services", ~r/\b(2\s?HANDS)\b/i},
          {"Wellness & Massage Equipment", ~r/\b(OGAWA|OSIM|INADA|BREO|SNOWFIT)\b/i},
          {"Hospital / Medical Center",
           ~r/\b(ST\s?FRANCES\s?CABRINI|MAKATI\s?MEDICAL\s?CENTER|ASIAN\s?HOSPITAL)\b/i},
          {"Dental Clinic / Dental Care Top",
           ~r/\b(URBAN\s?SMILES|DENTAL|PYMY\s?LUXE\s?SMILES)\b/i},
          {"Pain Relief / Topical Ointment",
           ~r/\b(KATINKO|WHITE\s?FLOWER|TIGER\s?BALM|EFFICASCENT|OMEGA\s?PAIN\s?KILLER|PAIN\s?KILLER|VICKS)\b/i}
        ]
      },
      {
        "Groceries",
        [
          {"Supermarkets",
           ~r/\b(PUREGOLD|SM\s?HYPERMARKET|SM\s?SUPERMARKET|ROBINSONS\s?SUPERMARKET|LANDERS|S\s?&\s?R|WALTERMART|WMS|SHOPWISE|SAVEMORE|METRO\s?SUPERMARKET)\b/i},
          {"Specialty / Gourmet Stores", ~r/\b(SANTIS\s?DELI)\b/i}
        ]
      },
      {
        "Retail & Shopping",
        [
          {"Malls & Department Stores",
           ~r/\b(LANDMARK|SM\s?STORE|AYALA\s?MALLS|GREENBELT|GLORIETTA|MEGAMALL|SM\s?AURA|RUSTANS|DEPARTMENT)\b/i},
          {"Malls & Department Stores", ~r/(SM\s?STORE)/i},
          {"Online Shopping", ~r/\b(LAZADA|SHOPEE|ZALORA|SHEIN|SHEIN\.COM)\b/i},
          {"Pet Supplies", ~r/\b(PET\s?EXPRESS)\b/i},
          {"Luxury Fashion / Designer Brand",
           ~r/\b(PRADA|GUCCI|LOUIS\s?VITTON|DIOR|BURBERRY)\b/i},
          {"Electronics",
           ~r/\b(OCTAGON|POWER\s?MAC|BEYOND\s?THE\s?BOX|ABENSON|ANSON?S|POWERMAC|DIGITAL\s?WALKER|SAMSUNG|APPLE\s?STORE|HUAWEI|MI\s?STORE)\b/i},
          {"Electronics",
           ~r/(OCTAGON|POWER\s?MAC|BEYOND\s?THE\s?BOX|ABENSON|ANSON?S|ANSON|POWERMAC|DIGITAL\s?WALKER|SAMSUNG|APPLE\s?STORE|HUAWEI|MI\s?STORE)/i},
          {"Clothing & Apparel",
           ~r/\b(GINGERSNAPS|ONESIMUS|UNIQLO|ZARA|H&M|BENCH|PENSHOPPE|MANGO|FOREVER\s?21)\b/i},
          {"Home Improvement & Hardware", ~r/\b(MR\s?DIY|HANDYMAN|ACE\s?HARDWARE)\b/i},
          {"Baby & Kids / Parenting Supplies",
           ~r/\b(EDAMAMA|MOTHERCARE|MUSTELA|AVEENO|SEBAMED|PIGEON|JOHNSONS\s?BABY)\b/i},
          {"Furniture & Home Stores",
           ~r/\b(OUR\s?HOME|IKEA|ASHLEY\s?FURNITURE|CRATE\s?&\s?BARREL|WEST\s?ELM|POTTERY\s?BARN|SM\s?HOME|OUR\s?HOME|ALLHOME|HOMEMAKER|HOMECENTRE)\b/i},
          {"Lifestyle", ~r/(\@TOKYO)/i},
          {"Eyewear / Optical Stores",
           ~r/\b(OWNDAYS|IDEAL\s?VISION|VISION\s?EXPRESS|SUNNIES\s?STUDIOS|OPTICAL\s?88)\b/i},
          {"Bookstores", ~r/\b(NBS|POWERBOOKS|FULLY\s?BOOKED)\b/i},
          {"Footwear / Shoe Store",
           ~r/\b(NEW\s?BALANCE|SKETCHERS|NIKE|ADIDAS|WORLD\s?BALANCE|PUMA|ROCK\s?N\'\s?SOLE)\b/i},
          {"Florists / Flower Shops",
           ~r/\b(FLOWER\s?FARM|FLOWERS\s?FOR\s?ALL\s?SEASONS|ISLAND\s?ROSE|FLOWERSTORE\s?MANILA|FLORA\s?VIDA|PETAL\s?&\s?STEM)\b/i},
          {"Home Appliances / Kitchen Equipment", ~r/\b(KITCHENAID|BREVILLE|SMEG|OSTER)\b/i},
          {"Discount Store / Variety Store", ~r/\b(MINISO|DAISO)\b/i}
        ]
      },
      {
        "Digital Payments",
        [
          {"E-wallets", ~r/\b(GCASH|MAYA|PAYMAYA|GRABPAY|SHOPEEPAY|LAZPAY|COINS\.PH)\b/i},
          {"Payment Gateways", ~r/\b(PAYPAL|DRAGONPAY|PAYONEER|STRIPE|BILLEASE|ATOME)\b/i}
        ]
      },
      {
        "Utilities",
        [
          {"Bills & Services",
           ~r/\b(MERALCO|MAYNILAD|MANILA\s?WATER|GLOBE|SMART|PLDT|CONVERGE|DITO|SKY\s?CABLE)\b/i},
          {"Bills & Services", ~r/\b(CONVERGE\s?ICT)\b/i},
          {"Toll & Transport", ~r/\b(EASYTRIP|AUTOSWEEP)\b/i}
        ]
      },
      {
        "Financial Services",
        [
          {"Insurance / Investments", ~r/\b(MANULIFE|SUN\s?LIFE|PRU\s?LIFE|AXA)\b/i},
          {"Bills Payment", ~r/\b(BAYAD\s?ONLINE)\b/i},
          {"Government Services",
           ~r/\b(SSS|DFA|TIEZA|LTO|HOME\s?AFFAIRS|PAG\s?IBIG\s?FUND\s?HDMF|HDMF|PAG\s?IBIG)\b/i}
        ]
      },
      {
        "Digital Services",
        [
          {"Developer Tools / Software Subscription",
           ~r/\b(GITHUB|GITHUB\.COM|FLY\.IO|AWS|HEROKU\*|CLOUDFLARE)\b/i},
          {"AI Tools / Software Subscription", ~r/(OPENAI|ANTHROPIC)/i}
        ]
      },
      {
        "Education & Learning",
        [
          {"Online Courses / Software Development Training",
           ~r/\b(PRAGMATIC\s?STUDIO|UDEMY|PLURALSIGHT|COURSERA)\b/i}
        ]
      },
      {
        "Entertainment & Subscriptions",
        [
          {"Streaming Services",
           ~r/\b(NETFLIX|SPOTIFY|DISNEY\+|YOUTUBE\s?PREMIUM|HBO\s?GO|PRIME\s?VIDEO|VIVAMAX|IQIYI|CRUNCHYROLL|VIU)\b/i},
          {"Gaming",
           ~r/\b(PLAYSTATION|XBOX\s?LIVE|STEAM|STEAMGAMES\.COM|EPIC\s?GAMES|RIOT|GARENA|DATABLITZ|GAMEXTREME|ITECH|GAMEONE|GAMELINE)\b/i},
          {"Patreon & Others", ~r/\b(PATREON|ONLYFANS|FANHOUSE)\b/i},
          {"App Store & Subscriptions", ~r/\b(APPLE.COM\/BILL\s?ITUNES.COM)\b/i}
        ]
      },
      {
        "Transportation",
        [
          {"Ride Hailing", ~r/\b(GRAB|ANGKAS|JOYRIDE|LYFT|UBER)\b/i},
          {"Fuel", ~r/\b(SHELL|PETRON|CALTEX|TOTAL|UNIOIL)\b/i},
          {"Auto Repair Services", ~r/\b(MINERVA\s?TIRE\s?DEPOT|TIREX)\b/i}
        ]
      },
      {
        "Automative",
        [
          {"Car Dealerships",
           ~r/\b(Toyota|Honda|Nissan|Mitsubishi|Ford|Mazda|Suzuki|Hyundai|Kia|Chevrolet|Isuzu|Subaru)\b/i}
        ]
      },
      {
        "Travel / Airlines",
        [
          {"Local Airlines",
           ~r/\b(CEBU\s?PAC|CEBU\s?PACIFIC|CEBU\s?AIR|AIR\s?ASIA|PAL|PHILIPPINE\s?AIRLINES)\b/i},
          {"International Airlines",
           ~r/\b(SINGAPORE\s?AIRLINES|SCOOT|CATHAY\s?PACIFIC|JAPAN\s?AIRLINES|ANA|KOREAN\s?AIR|ASIANA|EMIRATES|ETIHAD|QATAR\s?AIRWAYS|UNITED\s?AIRLINES|DELTA|QANTAS)\b/i},
          {"International Airlines",
           ~r/(SINGAPORE\s?AIR|SCOOT|CATHAY\s?PACIFIC|JAPAN\s?AIRLINES|ANA|KOREAN\s?AIR|ASIANA|EMIRATES|ETIHAD|QATAR\s?AIRWAYS|UNITED\s?AIRLINES|DELTA|QANTAS)/i}
        ]
      },
      {
        "Travel & Leisure",
        [
          {"Tours & Activities Booking Platform",
           ~r/\b(AGODA|KLOOK|TRAVELOKA|AIRBNB|TRIP\.COM|GETYOURGUIDE)\b/i}
        ]
      },
      {
        "Hotels & Lodging",
        [
          {"Luxury Hotels",
           ~r/\b(SHANGRI\-LA|SOFITEL|CONRAD|FAIRMONT|RAFFLES|MARRIOTT|HYATT|PENINSULA|NUWA|OKADA|DIAMOND\s?HOTEL)\b/i},
          {"Beach Resorts",
           ~r/\b(PUNTA\s?FUEGO|PICO\s?DE\s?LORO|STILTS|HENANN|CRIMSON|AMORITA|MOVENPICK|THE\s?LIND|ASTORIA|TWO\s?SEASONS|THE\s?DISTRICT|NAMI|AUREO|BLUEWATER)\b/i},
          {"Business Hotels",
           ~r/\b(LINDEN\s?SUITES|NOVOTEL|SAVOY|BELMONT|SEDA|RICHMONDE|HOLIDAY\s?INN|PARK\s?INN|RED\s?PLANET|MICROTEL|CITADINES|ASCOTT|THE\s?MANOR)\b/i},
          {"Business Hotels", ~r/(LINDEN)/i}
        ]
      }
    ]
  end

  @fallback_category "Others"

  @doc """
  Returns {category, subcategory} if found, or {"Uncategorized", nil} otherwise.
  """
  def categorize(description) when is_binary(description) do
    Enum.find_value(categories(), {"Others", nil}, fn {category, subs} ->
      Enum.find_value(subs, fn {sub, regex} ->
        # KachingkoApi.TransactionCategorizer.categorize("MERCURY")
        if Regex.match?(regex, description), do: {category, sub}
      end)
    end)
  end
end
