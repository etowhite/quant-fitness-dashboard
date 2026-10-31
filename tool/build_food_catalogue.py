import csv,json,pathlib,re,sys
root=pathlib.Path('.toolchains/usda/FoodData_Central_sr_legacy_food_csv_2018-04')
foods=list(csv.DictReader((root/'food.csv').open(encoding='utf8')))
nutrients={}
for r in csv.DictReader((root/'food_nutrient.csv').open(encoding='utf8')):
 if r['nutrient_id'] in ['1008','1003','1004','1005']:
  nutrients.setdefault(r['fdc_id'],{})[r['nutrient_id']]=float(r['amount'])
# Literal English prefixes identify USDA records; Russian labels describe the food.
definitions='''
Молочка|Молоко цельное 3,25%|Milk, whole, 3.25%
Молочка|Молоко 2%|Milk, reduced fat, fluid, 2%
Молочка|Молоко 1%|Milk, lowfat, fluid, 1%
Молочка|Молоко обезжиренное|Milk, nonfat, fluid
Молочка|Молоко козье|Milk, goat
Молочка|Молоко овечье|Milk, sheep
Молочка|Пахта|Milk, buttermilk, fluid
Молочка|Молоко сухое цельное|Milk, dry, whole
Молочка|Молоко сухое обезжиренное|Milk, dry, nonfat
Молочка|Молоко сгущенное с сахаром|Milk, canned, condensed, sweetened
Молочка|Сливки жирные|Cream, fluid, heavy
Молочка|Сливки легкие|Cream, fluid, light
Молочка|Сметана|Cream, sour, cultured
Молочка|Йогурт натуральный цельный|Yogurt, plain, whole milk
Молочка|Йогурт натуральный нежирный|Yogurt, plain, low fat
Молочка|Йогурт натуральный обезжиренный|Yogurt, plain, skim milk
Молочка|Йогурт греческий натуральный|Yogurt, Greek, plain
Молочка|Йогурт фруктовый|Yogurt, fruit, low fat
Молочка|Кефир нежирный|Kefir, lowfat
Сыры|Сыр чеддер|Cheese, cheddar
Сыры|Сыр гауда|Cheese, gouda
Сыры|Сыр эдам|Cheese, edam
Сыры|Сыр швейцарский|Cheese, swiss
Сыры|Сыр пармезан|Cheese, parmesan
Сыры|Сыр моцарелла цельномолочный|Cheese, mozzarella, whole milk
Сыры|Сыр фета|Cheese, feta
Сыры|Сыр камамбер|Cheese, camembert
Сыры|Сыр бри|Cheese, brie
Сыры|Сыр с голубой плесенью|Cheese, blue
Сыры|Сыр рикотта|Cheese, ricotta
Сыры|Сыр сливочный|Cheese, cream
Сыры|Сыр козий мягкий|Cheese, goat, soft
Молочка|Зерненый творог 4%|Cheese, cottage, creamed
Молочка|Зерненый творог 2%|Cheese, cottage, lowfat, 2%
Молочка|Зерненый творог 1%|Cheese, cottage, lowfat, 1%
Яйца|Яйцо куриное целое|Egg, whole
Яйца|Белок куриного яйца|Egg, white
Яйца|Желток куриного яйца|Egg, yolk
Яйца|Яйцо перепелиное|Egg, quail
Яйца|Яйцо утиное|Egg, duck
Яйца|Яйцо гусиное|Egg, goose
Масла|Масло сливочное соленое|Butter, salted
Масла|Масло сливочное несоленое|Butter, without salt
Масла|Масло топленое|Butter oil, anhydrous
Масла|Масло подсолнечное|Oil, sunflower
Масла|Масло оливковое|Oil, olive
Масла|Масло рапсовое|Oil, canola
Масла|Масло кукурузное|Oil, corn
Масла|Масло соевое|Oil, soybean
Масла|Масло льняное|Oil, flaxseed
Масла|Масло кунжутное|Oil, sesame
Масла|Масло кокосовое|Oil, coconut
Масла|Масло арахисовое|Oil, peanut
Масла|Масло грецкого ореха|Oil, walnut
Масла|Свиной жир|Lard
Крупы и макароны|Рис белый длиннозерный|Rice, white, long-grain, regular
Крупы и макароны|Рис белый среднезерный|Rice, white, medium-grain
Крупы и макароны|Рис белый круглозерный|Rice, white, short-grain
Крупы и макароны|Рис бурый длиннозерный|Rice, brown, long-grain
Крупы и макароны|Рис бурый среднезерный|Rice, brown, medium-grain
Крупы и макароны|Рис дикий|Wild rice
Крупы и макароны|Гречка ядрица обжаренная|Buckwheat groats, roasted
Крупы и макароны|Гречка цельная|Buckwheat
Крупы и макароны|Овес цельный|Oats
Крупы и макароны|Овсяные хлопья|Cereals, oats, regular and quick
Крупы и макароны|Овсяные хлопья необогащенные|Cereals, oats, regular and quick, not fortified
Крупы и макароны|Перловая крупа|Barley, pearled
Крупы и макароны|Ячмень цельный|Barley, hulled
Крупы и макароны|Пшено|Millet
Крупы и макароны|Булгур|Bulgur
Крупы и макароны|Кускус|Couscous
Крупы и макароны|Киноа|Quinoa
Крупы и макароны|Амарант|Amaranth grain
Крупы и макароны|Манная крупа|Semolina
Крупы и макароны|Мука пшеничная универсальная|Wheat flour, white, all-purpose
Крупы и макароны|Мука цельнозерновая|Wheat flour, whole-grain
Крупы и макароны|Мука ржаная|Rye flour
Крупы и макароны|Мука рисовая|Rice flour
Крупы и макароны|Мука гречневая|Buckwheat flour
Крупы и макароны|Мука кукурузная|Corn flour, whole-grain
Крупы и макароны|Крупа кукурузная|Cornmeal, whole-grain
Крупы и макароны|Отруби пшеничные|Wheat bran
Крупы и макароны|Отруби овсяные|Oat bran
Крупы и макароны|Зародыши пшеницы|Wheat germ, crude
Крупы и макароны|Макароны необогащенные|Pasta, dry, unenriched
Крупы и макароны|Макароны вареные необогащенные|Pasta, cooked, unenriched
Крупы и макароны|Макароны цельнозерновые|Pasta, whole-wheat
Крупы и макароны|Спагетти|Spaghetti
Крупы и макароны|Лапша яичная|Noodles, egg
Крупы и макароны|Лапша рисовая|Rice noodles
Овощи|Картофель|Potatoes, flesh and skin
Овощи|Картофель очищенный|Potatoes, flesh
Овощи|Морковь|Carrots
Овощи|Свекла|Beets
Овощи|Капуста белокочанная|Cabbage
Овощи|Капуста краснокочанная|Cabbage, red
Овощи|Капуста савойская|Cabbage, savoy
Овощи|Капуста квашеная|Sauerkraut
Овощи|Капуста пекинская|Cabbage, chinese (pe-tsai)
Овощи|Капуста цветная|Cauliflower
Овощи|Брокколи|Broccoli
Овощи|Капуста брюссельская|Brussels sprouts
Овощи|Кольраби|Kohlrabi
Овощи|Кабачок цукини|Squash, summer, zucchini, includes skin
Овощи|Тыква|Pumpkin
Овощи|Баклажан|Eggplant
Овощи|Огурец с кожурой|Cucumber, with peel
Овощи|Огурец очищенный|Cucumber, peeled
Овощи|Томат красный|Tomatoes, red, ripe
Овощи|Томат зеленый|Tomatoes, green
Овощи|Перец сладкий красный|Peppers, sweet, red
Овощи|Перец сладкий зеленый|Peppers, sweet, green
Овощи|Перец сладкий желтый|Peppers, sweet, yellow
Овощи|Перец острый красный|Peppers, hot chili, red
Овощи|Лук репчатый|Onions
Овощи|Лук зеленый|Onions, spring or scallions
Овощи|Лук порей|Leeks
Овощи|Чеснок|Garlic
Овощи|Редис|Radishes
Овощи|Репа|Turnips
Овощи|Брюква|Rutabagas
Овощи|Корень сельдерея|Celeriac
Овощи|Сельдерей стеблевой|Celery
Овощи|Пастернак|Parsnips
Овощи|Спаржа|Asparagus
Овощи|Шпинат|Spinach
Овощи|Щавель|Sorrel
Овощи|Салат листовой зеленый|Lettuce, green leaf
Овощи|Салат айсберг|Lettuce, iceberg
Овощи|Салат ромэн|Lettuce, cos or romaine
Овощи|Руккола|Arugula
Овощи|Укроп|Dill weed, fresh
Овощи|Петрушка|Parsley, fresh
Овощи|Кинза|Coriander (cilantro) leaves
Овощи|Базилик|Basil, fresh
Овощи|Кресс-салат|Cress, garden
Овощи|Кукуруза сладкая желтая|Corn, sweet, yellow
Овощи|Зеленый горошек|Peas, green
Овощи|Фасоль стручковая|Beans, snap, green
Овощи|Шампиньоны белые|Mushrooms, white
Овощи|Грибы вешенки|Mushrooms, oyster
Овощи|Грибы шиитаке|Mushrooms, shiitake
Овощи|Томатная паста|Tomato products, canned, paste
Овощи|Огурцы маринованные|Pickles, cucumber, dill
Овощи|Оливки зеленые|Olives, pickled, canned or bottled, green
Овощи|Маслины|Olives, ripe, canned
Овощи|Морская капуста|Seaweed, kelp
Фрукты и ягоды|Яблоко с кожурой|Apples, raw, with skin
Фрукты и ягоды|Яблоко без кожуры|Apples, raw, without skin
Фрукты и ягоды|Яблоко сушеное|Apples, dried
Фрукты и ягоды|Груша|Pears
Фрукты и ягоды|Банан|Bananas
Фрукты и ягоды|Апельсин|Oranges, raw
Фрукты и ягоды|Мандарин|Tangerines, (mandarin oranges), raw
Фрукты и ягоды|Грейпфрут розовый|Grapefruit, raw, pink and red
Фрукты и ягоды|Лимон|Lemons, raw
Фрукты и ягоды|Лайм|Limes, raw
Фрукты и ягоды|Киви зеленый|Kiwifruit, green
Фрукты и ягоды|Ананас|Pineapple
Фрукты и ягоды|Манго|Mangos
Фрукты и ягоды|Авокадо|Avocados, raw
Фрукты и ягоды|Персик|Peaches
Фрукты и ягоды|Нектарин|Nectarines
Фрукты и ягоды|Абрикос|Apricots
Фрукты и ягоды|Слива|Plums
Фрукты и ягоды|Чернослив|Plums, dried
Фрукты и ягоды|Изюм|Raisins, seedless
Фрукты и ягоды|Финики|Dates
Фрукты и ягоды|Инжир|Figs
Фрукты и ягоды|Хурма|Persimmons, japanese
Фрукты и ягоды|Гранат|Pomegranates
Фрукты и ягоды|Айва|Quinces
Фрукты и ягоды|Арбуз|Watermelon
Фрукты и ягоды|Дыня канталупа|Melons, cantaloupe
Фрукты и ягоды|Дыня медовая|Melons, honeydew
Фрукты и ягоды|Виноград|Grapes, red or green
Фрукты и ягоды|Черешня|Cherries, sweet
Фрукты и ягоды|Вишня|Cherries, sour, red
Фрукты и ягоды|Клубника|Strawberries
Фрукты и ягоды|Малина|Raspberries
Фрукты и ягоды|Ежевика|Blackberries
Фрукты и ягоды|Черника голубика|Blueberries
Фрукты и ягоды|Смородина черная|Currants, european black
Фрукты и ягоды|Смородина красная и белая|Currants, red and white
Фрукты и ягоды|Крыжовник|Gooseberries
Фрукты и ягоды|Клюква|Cranberries
Фрукты и ягоды|Черника дикая|Blueberries, wild
Фрукты и ягоды|Шиповник|Rose hips
Фрукты и ягоды|Шелковица|Mulberries
Фрукты и ягоды|Сок яблочный|Apple juice
Фрукты и ягоды|Сок апельсиновый|Orange juice
Фрукты и ягоды|Сок виноградный|Grape juice
Фрукты и ягоды|Сок томатный|Tomato juice
Орехи и семена|Арахис|Peanuts, all types
Орехи и семена|Миндаль|Nuts, almonds
Орехи и семена|Орех грецкий|Nuts, walnuts, english
Орехи и семена|Фундук|Nuts, hazelnuts or filberts
Орехи и семена|Кешью|Nuts, cashew nuts
Орехи и семена|Фисташки|Nuts, pistachio nuts
Орехи и семена|Орех кедровый|Nuts, pine nuts
Орехи и семена|Орех бразильский|Nuts, brazilnuts
Орехи и семена|Орех пекан|Nuts, pecans
Орехи и семена|Макадамия|Nuts, macadamia nuts
Орехи и семена|Кокос мякоть|Nuts, coconut meat
Орехи и семена|Семечки подсолнечника|Seeds, sunflower seed kernels
Орехи и семена|Семечки тыквы|Seeds, pumpkin and squash seed kernels
Орехи и семена|Семена кунжута|Seeds, sesame seeds, whole
Орехи и семена|Семена льна|Seeds, flaxseed
Орехи и семена|Семена чиа|Seeds, chia seeds
Орехи и семена|Мак|Spices, poppy seed
Бобовые|Чечевица|Lentils
Бобовые|Нут|Chickpeas (garbanzo beans, bengal gram)
Бобовые|Фасоль красная|Beans, kidney, red
Бобовые|Фасоль белая|Beans, white
Бобовые|Фасоль черная|Beans, black
Бобовые|Фасоль пинто|Beans, pinto
Бобовые|Горох колотый|Peas, split
Бобовые|Маш|Mung beans, mature seeds
Бобовые|Соя|Soybeans, mature seeds
Бобовые|Тофу твердый|Tofu, raw, firm
Бобовые|Тофу мягкий|Tofu, soft
Бобовые|Соевый напиток|Soymilk, original and vanilla
Бобовые|Хумус|Hummus
Рыба и морепродукты|Лосось атлантический фермерский|Fish, salmon, Atlantic, farmed
Рыба и морепродукты|Лосось атлантический дикий|Fish, salmon, Atlantic, wild
Рыба и морепродукты|Горбуша|Fish, salmon, pink
Рыба и морепродукты|Нерка|Fish, salmon, sockeye
Рыба и морепродукты|Кета|Fish, salmon, chum
Рыба и морепродукты|Форель радужная|Fish, trout, rainbow, farmed
Рыба и морепродукты|Сельдь атлантическая|Fish, herring, Atlantic
Рыба и морепродукты|Скумбрия атлантическая|Fish, mackerel, Atlantic
Рыба и морепродукты|Треска атлантическая|Fish, cod, Atlantic
Рыба и морепродукты|Минтай|Fish, pollock, Alaska
Рыба и морепродукты|Хек|Fish, hake
Рыба и морепродукты|Пикша|Fish, haddock
Рыба и морепродукты|Судак|Fish, pike perch
Рыба и морепродукты|Щука|Fish, pike, northern
Рыба и морепродукты|Окунь|Fish, perch, mixed species
Рыба и морепродукты|Карп|Fish, carp
Рыба и морепродукты|Камбала|Fish, flatfish (flounder and sole species)
Рыба и морепродукты|Тунец светлый консервированный|Fish, tuna, light, canned in water
Рыба и морепродукты|Тунец желтоперый|Fish, tuna, fresh, yellowfin
Рыба и морепродукты|Сардины в масле|Fish, sardine, Atlantic, canned in oil
Рыба и морепродукты|Шпроты|Fish, sprat
Рыба и морепродукты|Икра рыбная смешанные виды|Fish, roe, mixed species
Рыба и морепродукты|Креветки|Crustaceans, shrimp, mixed species
Рыба и морепродукты|Краб|Crustaceans, crab, alaska king
Рыба и морепродукты|Мидии|Mollusks, mussel, blue
Рыба и морепродукты|Кальмар|Mollusks, squid, mixed species
Рыба и морепродукты|Осьминог|Mollusks, octopus, common
Рыба и морепродукты|Устрицы|Mollusks, oyster, eastern, wild
Птица|Куриное филе без кожи и кости|Chicken, broiler or fryers, breast, skinless, boneless, meat only
Птица|Куриная грудка без кожи|Chicken, broilers or fryers, breast, meat only
Птица|Куриное бедро без кожи|Chicken, broilers or fryers, thigh, meat only
Птица|Куриная голень без кожи|Chicken, broilers or fryers, drumstick, meat only
Птица|Куриные крылышки с кожей|Chicken, broilers or fryers, wing, meat and skin
Птица|Курица целая с кожей|Chicken, broilers or fryers, meat and skin
Птица|Куриная печень|Chicken, liver, all classes
Птица|Куриное сердце|Chicken, heart, all classes
Птица|Куриные желудки|Chicken, gizzard, all classes
Птица|Грудка индейки без кожи|Turkey, breast, from whole bird, meat only
Птица|Индейка фарш|Turkey, ground
Птица|Утка с кожей|Duck, domesticated, meat and skin
Птица|Утка без кожи|Duck, domesticated, meat only
Птица|Гусь с кожей|Goose, domesticated, meat and skin
Мясо|Говяжий фарш 90% постного мяса|Beef, ground, 90% lean meat / 10% fat
Мясо|Говяжий фарш 85% постного мяса|Beef, ground, 85% lean meat / 15% fat
Мясо|Говяжий фарш 80% постного мяса|Beef, ground, 80% lean meat / 20% fat
Мясо|Говяжья печень|Beef, variety meats and by-products, liver
Мясо|Говяжий язык|Beef, variety meats and by-products, tongue
Мясо|Говяжье сердце|Beef, variety meats and by-products, heart
Мясо|Говяжьи почки|Beef, variety meats and by-products, kidneys
Мясо|Свиная вырезка|Pork, fresh, loin, tenderloin, separable lean only
Мясо|Свиная лопатка|Pork, fresh, shoulder
Мясо|Свиные ребрышки|Pork, fresh, spareribs
Мясо|Свиная печень|Pork, fresh, variety meats and by-products, liver
Мясо|Свиной фарш|Pork, ground
Мясо|Баранина фарш|Lamb, ground
Мясо|Телятина фарш|Veal, ground
Мясо|Кролик домашний|Game meat, rabbit, domesticated
Мясо|Конина|Game meat, horse
Мясо|Оленина фарш|Game meat, deer, ground
Колбасы|Ветчина нарезка|Ham, sliced, regular
Колбасы|Салями|Salami, dry or hard
Колбасы|Сосиски говяжьи|Frankfurter, beef
Колбасы|Сосиски мясные|Frankfurter, meat
Колбасы|Колбаса болонская|Bologna, beef and pork
Колбасы|Бекон свиной|Pork, cured, bacon
Хлеб и выпечка|Хлеб пшеничный белый|Bread, white, commercially prepared
Хлеб и выпечка|Хлеб цельнозерновой|Bread, whole-wheat, commercially prepared
Хлеб и выпечка|Хлеб ржаной|Bread, rye
Хлеб и выпечка|Хлеб пшеничный|Bread, wheat
Хлеб и выпечка|Хлеб овсяный|Bread, oatmeal
Хлеб и выпечка|Хлеб отрубной|Bread, reduced-calorie, wheat
Хлеб и выпечка|Багет французский|Bread, french or vienna
Хлеб и выпечка|Пита белая|Bread, pita, white
Хлеб и выпечка|Пита цельнозерновая|Bread, pita, whole-wheat
Хлеб и выпечка|Лепешка пшеничная|Tortillas, ready-to-bake or -fry, flour
Хлеб и выпечка|Лепешка кукурузная|Tortillas, ready-to-bake or -fry, corn
Хлеб и выпечка|Булочка сдобная|Rolls, dinner
Хлеб и выпечка|Круассан сливочный|Croissants, butter
Хлеб и выпечка|Бублик пшеничный|Bagels, plain
Хлеб и выпечка|Сухари панировочные|Bread crumbs, dry, grated, plain
Хлеб и выпечка|Крекер соленый|Crackers, saltines
Хлеб и выпечка|Блинчики простые|Pancakes, plain
Хлеб и выпечка|Вафли простые|Waffles, plain
Сладости|Сахар белый|Sugars, granulated
Сладости|Сахар коричневый|Sugars, brown
Сладости|Мед|Honey
Сладости|Шоколад молочный|Candies, milk chocolate
Сладости|Шоколад темный 70–85%|Chocolate, dark, 70-85%
Сладости|Шоколад темный 60–69%|Chocolate, dark, 60-69%
Сладости|Шоколад белый|Candies, white chocolate
Сладости|Драже желейное|Candies, jellybeans
Сладости|Зефир маршмеллоу|Candies, marshmallows
Сладости|Карамель|Candies, caramels
Сладости|Халва|Candies, halavah
Сладости|Варенье фруктовое|Jams and preserves
Сладости|Мороженое ванильное|Ice creams, vanilla
Сладости|Мороженое шоколадное|Ice creams, chocolate
Сладости|Какао-порошок без сахара|Cocoa, dry powder, unsweetened
Сладости|Печенье овсяное|Cookies, oatmeal
Сладости|Печенье сахарное|Cookies, sugar
Готовые блюда|Суп куриный с лапшой|Soup, chicken noodle
Готовые блюда|Суп томатный|Soup, tomato
Готовые блюда|Суп грибной сливочный|Soup, cream of mushroom
Готовые блюда|Суп гороховый|Soup, pea, green
Готовые блюда|Суп чечевичный|Soup, lentil
Готовые блюда|Суп овощной|Soup, vegetable
Готовые блюда|Салат картофельный|Potato salad
Готовые блюда|Салат из капусты|Coleslaw
Готовые блюда|Омлет|Egg, whole, cooked, omelet
Готовые блюда|Картофельное пюре|Potatoes, mashed
Готовые блюда|Лазанья мясная|Lasagna with meat sauce
Готовые блюда|Макароны с сыром|Macaroni and cheese
Готовые блюда|Пицца с сыром|Pizza, cheese topping
Соусы|Майонез обычный|Salad dressing, mayonnaise, regular
Соусы|Горчица столовая|Mustard, prepared, yellow
Соусы|Кетчуп|Catsup
Соусы|Соус соевый|Soy sauce made from soy and wheat
Соусы|Соус томатный|Tomato products, canned, sauce
Специи|Перец черный молотый|Spices, pepper, black
Специи|Корица|Spices, cinnamon, ground
Специи|Имбирь молотый|Spices, ginger, ground
Специи|Куркума|Spices, turmeric, ground
Специи|Паприка|Spices, paprika
Напитки|Кофе черный|Beverages, coffee, brewed
Напитки|Чай черный|Beverages, tea, black, brewed
Напитки|Чай зеленый|Beverages, tea, green, brewed
'''
selected=[]; used=set(); names=set(); missing=[]
for line in definitions.strip().splitlines():
 cat,ru,prefix=line.split('|'); prefix=prefix.lower()
 matches=[f for f in foods if (f['description'].lower()==prefix or f['description'].lower().startswith(prefix+',') or f['description'].lower().startswith(prefix+' ')) and len(nutrients.get(f['fdc_id'],{}))==4]
 # Avoid branded records and prefer generic, unfortified reference foods.
 matches.sort(key=lambda f: (0 if any(x in f['description'].lower() for x in [', raw', ', uncooked']) else 1 if ', cooked' in f['description'].lower() else 2, len(f['description']), f['description']))
 count=0
 for f in matches:
  if f['fdc_id'] in used: continue
  d=f['description'].lower()
  if any(s in d for s in ['babyfood','gerber','restaurant','mcdonald','wendy','burger king','frozen dinner','dry mix','dry, mix','refrigerated dough','with fruit','nonfat milk solids','sprouted']): continue
  mods=[]
  for en,rus in [('raw','сырое'),('uncooked','сухое'),('dry','сухое'),('cooked','приготовленное'),('boiled','отварное'),('roasted','запеченное'),('fried','жареное'),('canned','консервы'),('frozen','замороженное'),('dried','сушеное'),('toasted','поджаренное'),('smoked','копченое'),('pickled','маринованное'),('in oil','в масле'),('in water','в воде'),('without salt','без соли'),('salt added','с солью'),('with salt','с солью'),('in syrup','в сиропе'),('in juice','в соке'),('drained','без жидкости'),('nonfat','обезжиренное'),('lowfat','нежирное'),('low fat','нежирное'),('reduced fat','пониженная жирность'),('unsweetened','без сахара'),('sweetened','с сахаром'),('heavy syrup','густой сироп'),('light syrup','легкий сироп'),('stewed','тушеное'),('whole milk','цельное молоко'),('low sodium','мало натрия'),('condensed','концентрат'),('ready-to-serve','готовый'),('with added solution','с рассолом'),('in heavy syrup','густой сироп')]:
   if re.search(r'(?<![a-z])'+en+r'(?![a-z])',d) and rus not in mods: mods.append(rus)
  if 'boiled' in d and 'приготовленное' in mods: mods.remove('приготовленное')
  if 'roasted' in d and 'приготовленное' in mods: mods.remove('приготовленное')
  if 'fried' in d and 'приготовленное' in mods: mods.remove('приготовленное')
  if cat=='Крупы и макароны':
   mods=[('сухое' if m=='сырое' else 'отварное' if m=='приготовленное' else m) for m in mods if m!='запеченное']
  name=ru+(' ('+', '.join(mods)+')' if mods else '')
  if name in names: continue
  n=nutrients[f['fdc_id']]
  if n['1008']>1000 or any(n[k]>100 for k in ['1003','1004','1005']): continue
  selected.append(dict(id='usda-sr-'+f['fdc_id'],name=name,category=cat,calories=n['1008'],proteins=n['1003'],fats=n['1004'],carbs=n['1005'],source='USDA FoodData Central SR Legacy (2018)',sourceId=int(f['fdc_id']),sourceDescription=f['description']))
  used.add(f['fdc_id']); names.add(name); count+=1
  if count==2: break
 if not count: missing.append(ru)
print('Selected',len(selected),'missing',missing)
pathlib.Path('assets/data/ru_base_foods.json').write_text(json.dumps({'version':1,'units':'per 100 g edible portion','sourceUrl':'https://fdc.nal.usda.gov/download-datasets/','license':'USDA public domain / CC0','foods':selected},ensure_ascii=False,indent=2),encoding='utf8')
pathlib.Path('.toolchains/catalogue-review.tsv').write_text('\n'.join(str(r['sourceId'])+'\t'+r['name']+'\t'+r['sourceDescription'] for r in selected),encoding='utf8')
