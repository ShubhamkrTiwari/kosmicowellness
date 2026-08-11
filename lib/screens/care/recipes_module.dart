import 'package:flutter/material.dart';
import 'recipe_detail_screen.dart';

class RecipesModule extends StatelessWidget {
  const RecipesModule({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(colorScheme),
          const SizedBox(height: 24),
          _buildSectionTitle('Diabetes Friendly Recipes'),
          const SizedBox(height: 16),
          _buildRecipeGrid(colorScheme, context),
          const SizedBox(height: 24),
          _buildSmartSubstitutions(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search ingredients or recipes...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget _buildRecipeGrid(ColorScheme colorScheme, BuildContext context) {
    final List<Map<String, dynamic>> recipes = [
      {
        'name': 'Quinoa Pulao',
        'carbs': '15g Carbs',
        'image': 'https://images.unsplash.com/photo-1543339308-43e59d6b73a6?auto=format&fit=crop&w=800&q=80',
        'protein': '12g',
        'fiber': '8g',
        'prep': '25 min',
        'category': 'Lunch / Dinner',
        'ingredients': ['1 cup Quinoa', 'Mixed Vegetables (Peas, Carrots, Beans)', 'Cumin Seeds', 'Lemon Juice', 'Fresh Coriander'],
        'steps': [
          'Start by rinsing 1 cup of quinoa thoroughly in a fine-mesh strainer under cold running water for at least 2 minutes. This removes the natural bitter coating (saponin).',
          'Heat a teaspoon of olive oil or ghee in a large saucepan over medium heat. Add half a teaspoon of cumin seeds and let them sizzle for 30 seconds until aromatic.',
          'Add finely chopped onions, carrots, beans, and peas. Sauté the vegetables for 3-4 minutes until they are slightly tender but still have a bite.',
          'Add the rinsed quinoa to the pan and toast it with the vegetables for 1 minute, stirring constantly to enhance its nutty flavor.',
          'Pour in 2 cups of water (or low-sodium vegetable broth) and add a pinch of salt. Bring the mixture to a rolling boil.',
          'Once boiling, reduce the heat to the lowest setting, cover the pan with a tight-fitting lid, and simmer undisturbed for 15-18 minutes until all liquid is absorbed.',
          'Remove from heat and let it sit covered for 5 minutes. This allows the steam to finish the cooking process perfectly.',
          'Finally, fluff the quinoa gently with a fork. Add a squeeze of fresh lemon juice and garnish with freshly chopped coriander leaves before serving.'
        ],
        'tips': 'For extra protein, you can add some boiled chickpeas or sautéed tofu cubes to the pulao.'
      },
      {
        'name': 'Moong Dal Chilla',
        'carbs': '10g Carbs',
        'image': 'https://images.unsplash.com/photo-1626074353765-517a681e40be?auto=format&fit=crop&w=800&q=80',
        'protein': '14g',
        'fiber': '6g',
        'prep': '15 min',
        'category': 'Breakfast',
        'ingredients': ['1 cup Yellow Moong Dal', '2 Green Chilies', '1 inch Ginger', 'Pinch of Hing', 'Salt to taste'],
        'steps': [
          'Wash the moong dal thoroughly and soak it in enough water for at least 2-3 hours. If you are in a hurry, soak it in hot water for 30 minutes.',
          'Drain the soaking water and transfer the dal to a blender. Add green chilies, ginger, and a very small amount of water.',
          'Grind until you get a smooth, pancake-like batter consistency. It should not be too runny.',
          'Transfer the batter to a bowl and add hing (asafoetida), salt, and optional finely chopped coriander or grated carrots.',
          'Heat a non-stick tawa or griddle on medium heat. Lightly grease it with a few drops of oil.',
          'Pour a ladleful of batter in the center of the tawa and spread it gently in a circular motion to form a thin crepe.',
          'Drizzle a little oil around the edges and cook for 2-3 minutes until the bottom turns golden brown and crispy.',
          'Flip the chilla and cook the other side for another 1-2 minutes until done.',
          'Serve hot with mint chutney or a side of plain curd.'
        ],
        'tips': 'Soaking the dal for longer makes the chillas softer and easier to digest.'
      },
      {
        'name': 'Baked Fish',
        'carbs': '2g Carbs',
        'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=800&q=80',
        'protein': '22g',
        'fiber': '0g',
        'prep': '20 min',
        'category': 'Dinner',
        'ingredients': ['250g Fish Fillet (Sea Bass or Salmon)', '3 cloves Garlic', '1 Lemon', 'Black Pepper', 'Olive Oil'],
        'steps': [
          'Pat the fish fillets dry with a paper towel. This ensures the fish sears and bakes rather than steams.',
          'In a small bowl, mix 1 tablespoon of olive oil, minced garlic, half a teaspoon of black pepper, and salt.',
          'Rub this marinade all over the fish fillets and let them sit for 10-15 minutes to absorb the flavors.',
          'Preheat your oven to 200°C (400°F). Line a baking tray with parchment paper or lightly grease it.',
          'Place the fillets on the tray and place a few thin lemon slices on top of each fillet.',
          'Bake for 12-15 minutes, depending on the thickness of the fish. It is done when the flesh is opaque and flakes easily with a fork.',
          'Be careful not to overcook, as fish can become dry very quickly.',
          'Garnish with fresh parsley and serve with a side of steamed asparagus or a green salad.'
        ],
        'tips': 'You can also use an air fryer at 180°C for 10-12 minutes for a quicker and crispier result.'
      },
      {
        'name': 'Sprouted Salad',
        'carbs': '8g Carbs',
        'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
        'protein': '10g',
        'fiber': '7g',
        'prep': '10 min',
        'category': 'Snack',
        'ingredients': ['2 cups Mixed Sprouts (Moong, Methi)', 'Cucumber', 'Tomato', 'Onion', 'Chaat Masala'],
        'steps': [
          'If you prefer them slightly soft, steam the mixed sprouts in a steamer or pressure cooker with a little water for 5 minutes.',
          'Drain the sprouts thoroughly and let them cool down to room temperature.',
          'Finely chop one medium onion, one tomato, and one small cucumber. You can also add chopped green chilies for heat.',
          'In a large mixing bowl, combine the sprouts with the chopped vegetables.',
          'Add half a teaspoon of chaat masala, a pinch of black salt, and a squeeze of fresh lemon juice.',
          'Toss everything together until well combined.',
          'Garnish with freshly chopped coriander leaves and a handful of roasted peanuts for crunch.',
          'Serve immediately as a refreshing and protein-packed snack or a light lunch side.'
        ],
        'tips': 'Adding a bit of pomegranate seeds can provide a nice sweetness and extra antioxidants.'
      },
      {
        'name': 'Oats Idli',
        'carbs': '12g Carbs',
        'image': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=800&q=80',
        'protein': '6g',
        'fiber': '5g',
        'prep': '30 min',
        'category': 'Breakfast',
        'ingredients': ['1 cup Rolled Oats', '1/2 cup Semolina (Rava)', '1 cup Curd', 'Grated Carrots', 'Eno Fruit Salt'],
        'steps': [
          'Dry roast 1 cup of oats in a pan on medium heat for 4-5 minutes until they turn aromatic and slightly crisp.',
          'Let them cool completely, then grind them into a fine powder using a dry blender jar.',
          'In the same pan, dry roast the semolina (rava) for 2-3 minutes. This step is optional but makes idlis less sticky.',
          'In a mixing bowl, combine the oats powder, roasted semolina, and curd. Add a little water to form a thick batter.',
          'Add grated carrots, finely chopped coriander, and a pinch of salt. Mix well and let the batter rest for 15 minutes.',
          'Check the consistency after resting; oats absorb water, so you might need to add a few more tablespoons of water.',
          'Grease the idli molds with a drop of oil. Bring water to a boil in your idli steamer.',
          'Just before steaming, add half a teaspoon of Eno fruit salt to the batter and stir gently. The batter will become frothy.',
          'Immediately pour the batter into the molds and steam on medium-high heat for 12-15 minutes.',
          'Let the idlis cool for a minute before scooping them out. Serve with ginger-tomato chutney.'
        ],
        'tips': 'You can add finely chopped beans and capsicum to the batter for a more colorful and nutritious breakfast.'
      },
      {
        'name': 'Tofu Stir Fry',
        'carbs': '7g Carbs',
        'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
        'protein': '18g',
        'fiber': '4g',
        'prep': '15 min',
        'category': 'Lunch',
        'ingredients': ['200g Extra Firm Tofu', 'Broccoli Florets', 'Bell Peppers', 'Low Sodium Soy Sauce', 'Sesame Seeds'],
        'steps': [
          'Wrap the firm tofu block in a clean kitchen towel or paper towels and place a heavy object on top for 10 minutes to drain excess water.',
          'Cut the pressed tofu into 1-inch cubes.',
          'Heat a teaspoon of sesame or peanut oil in a large wok or skillet over high heat.',
          'Add the tofu cubes and sear them for 5-6 minutes, turning occasionally, until they are golden and crispy on most sides. Remove and set aside.',
          'In the same pan, add broccoli florets, sliced bell peppers, and snap peas. Stir-fry on high heat for 3-4 minutes until they are vibrant but still crunchy.',
          'Add minced garlic and ginger and sauté for another minute.',
          'Return the tofu to the pan. Pour in 1 tablespoon of low-sodium soy sauce and a teaspoon of rice vinegar.',
          'Toss everything together for 1-2 minutes until the sauce coats all the ingredients evenly.',
          'Garnish with toasted sesame seeds and sliced green onions. Serve hot as is or over a small portion of brown rice.'
        ],
        'tips': 'Pressing the tofu is key to getting that crispy exterior texture without deep frying.'
      },
      {
        'name': 'Methi Thepla',
        'carbs': '18g Carbs',
        'image': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=800&q=80',
        'protein': '5g',
        'fiber': '6g',
        'prep': '25 min',
        'category': 'Breakfast / Travel',
        'ingredients': ['2 cups Whole Wheat Flour', '1 cup Fresh Methi Leaves', '1/2 cup Curd', 'Turmeric & Chili Powder'],
        'steps': [
          'Thoroughly wash the fresh methi (fenugreek) leaves and chop them very finely. Discard any thick stems.',
          'In a large mixing bowl, combine whole wheat flour, chopped methi, turmeric, red chili powder, and salt.',
          'Add half a cup of whisked curd. The acidity in the curd helps soften the bitterness of the methi and keeps the theplas soft.',
          'Knead the mixture into a soft, pliable dough. Use very little water only if necessary, as methi and curd provide moisture.',
          'Cover the dough and let it rest for 10-15 minutes.',
          'Divide the dough into small lemon-sized balls. Roll them out into very thin, even circles using a little dry flour for dusting.',
          'Heat a tawa on medium-high heat. Place the thepla on the hot tawa.',
          'When tiny bubbles appear, flip it and apply a tiny amount of oil. Flip again and apply oil on the other side.',
          'Press gently with a spatula and cook until golden brown spots appear on both sides.',
          'Stack them in a kitchen towel to keep them soft. Serve with a side of mango pickle or plain yogurt.'
        ],
        'tips': 'These stay fresh for 2-3 days, making them a perfect healthy snack for long journeys.'
      },
      {
        'name': 'Lentil Soup',
        'carbs': '14g Carbs',
        'image': 'https://images.unsplash.com/photo-1547592110-803993f2851d?auto=format&fit=crop&w=800&q=80',
        'protein': '11g',
        'fiber': '9g',
        'prep': '35 min',
        'category': 'Dinner',
        'ingredients': ['1 cup Red Lentils (Masoor Dal)', '1 Onion', '2 cloves Garlic', 'Vegetable Broth', 'Cumin & Paprika'],
        'steps': [
          'Rinse the red lentils under cold water until the water runs clear. Set aside.',
          'Heat a teaspoon of olive oil in a large pot. Sauté finely chopped onion, garlic, and celery for 5 minutes until soft.',
          'Add half a teaspoon each of ground cumin and paprika for a smoky flavor.',
          'Add the rinsed lentils to the pot and pour in 4 cups of vegetable broth (or water).',
          'Bring to a boil, then reduce the heat to low and simmer partially covered for 20-25 minutes.',
          'Red lentils cook quickly and will break down, thickening the soup naturally.',
          'For a creamier texture, you can use an immersion blender to partially blend the soup, leaving some whole lentils for texture.',
          'Add salt and plenty of black pepper to taste.',
          'Serve hot with a squeeze of lemon and some fresh coriander on top.'
        ],
        'tips': 'Adding a handful of spinach at the very end and letting it wilt adds extra iron and vitamins.'
      },
      {
        'name': 'Paneer Bhurji',
        'carbs': '5g Carbs',
        'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=800&q=80',
        'protein': '16g',
        'fiber': '2g',
        'prep': '15 min',
        'category': 'High Protein',
        'ingredients': ['200g Paneer', '2 Onions', '2 Tomatoes', '1 Green Capsicum', 'Ginger-Garlic Paste'],
        'steps': [
          'Crumble the fresh paneer using your hands or grate it roughly. Do not mash it into a paste.',
          'Finely chop onions, tomatoes, and capsicum. De-seed the tomatoes if you prefer a less mushy bhurji.',
          'Heat a teaspoon of oil or butter in a pan. Add half a teaspoon of cumin seeds.',
          'Add onions and sauté until they turn translucent and slightly golden.',
          'Add one teaspoon of ginger-garlic paste and sauté for another minute until the raw smell disappears.',
          'Add the chopped tomatoes and capsicum. Cook on medium flame until the vegetables are soft.',
          'Add turmeric powder, red chili powder, garam masala, and salt. Mix well.',
          'Add the crumbled paneer and toss it with the masala for 2-3 minutes. Do not overcook as paneer can become chewy.',
          'Finish with a generous amount of chopped coriander and a dash of lemon juice.',
          'Serve hot with a slice of whole-wheat bread or a multigrain roti.'
        ],
        'tips': 'Using home-made paneer makes this dish incredibly soft and creamy.'
      },
      {
        'name': 'Vegetable Dalia',
        'carbs': '22g Carbs',
        'image': 'https://images.unsplash.com/photo-1599021419847-d8a7a4ad414d?auto=format&fit=crop&w=800&q=80',
        'protein': '7g',
        'fiber': '10g',
        'prep': '20 min',
        'category': 'High Fiber',
        'ingredients': ['1 cup Broken Wheat (Dalia)', 'Mixed Vegetables', 'Cumin Seeds', 'Ginger', 'Curd for side'],
        'steps': [
          'Add the dalia to a dry pan and roast it on low-medium heat for 3-4 minutes until it turns a shade darker and gives a nutty aroma.',
          'In a pressure cooker, heat a teaspoon of oil. Add cumin seeds and let them splutter.',
          'Add finely chopped ginger and green chilies. Sauté for 30 seconds.',
          'Add a variety of chopped vegetables like peas, carrots, beans, and cauliflower. Cook for 2 minutes.',
          'Add the roasted dalia, salt, and 3 cups of water. The ratio should be 1 part dalia to 3 parts water for a porridge-like consistency.',
          'Close the lid and pressure cook for 2-3 whistles on medium flame.',
          'Allow the pressure to release naturally before opening the lid.',
          'Give it a good mix; the dalia should be soft and well-cooked.',
          'Garnish with coriander and serve warm with a bowl of fresh curd.'
        ],
        'tips': 'Dalia is a great low-GI alternative to white rice and keeps you full for longer.'
      },
      {
        'name': 'Chickpea Chaat',
        'carbs': '16g Carbs',
        'image': 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=80',
        'protein': '9g',
        'fiber': '8g',
        'prep': '10 min',
        'category': 'Snack',
        'ingredients': ['2 cups Boiled Chickpeas (Kabuli Chana)', 'Red Onion', 'Cucumber', 'Green Chutney', 'Roasted Cumin'],
        'steps': [
          'Soak chickpeas overnight and pressure cook them with salt until soft. Ensure they are drained completely.',
          'In a large bowl, take the boiled chickpeas and add finely chopped onion, cucumber, and tomatoes.',
          'Add a tablespoon of spicy green mint-coriander chutney and a teaspoon of sweet tamarind chutney (use sparingly).',
          'Sprinkle half a teaspoon of roasted cumin powder, red chili powder, and black salt.',
          'Squeeze half a lemon over the mixture and toss everything vigorously.',
          'Add some finely chopped raw mango or pomegranate seeds if they are in season for a flavor burst.',
          'Garnish with fresh coriander and serve as a healthy, fiber-rich evening snack.'
        ],
        'tips': 'You can also use canned chickpeas; just make sure to rinse them thoroughly under cold water to remove excess sodium.'
      },
      {
        'name': 'Bajra Rotla',
        'carbs': '20g Carbs',
        'image': 'https://images.unsplash.com/photo-1626776877927-433f6b6b5d03?auto=format&fit=crop&w=800&q=80',
        'protein': '4g',
        'fiber': '5g',
        'prep': '15 min',
        'category': 'Traditional',
        'ingredients': ['2 cups Bajra (Pearl Millet) Flour', 'Hot Water', 'Salt'],
        'steps': [
          'In a wide mixing bowl, take the bajra flour and a pinch of salt. Mix well.',
          'Add hot water gradually and start kneading. Bajra dough requires warm/hot water to become pliable as it is gluten-free.',
          'Knead the dough well with the palm of your hand for 4-5 minutes until it becomes smooth and soft.',
          'Divide into medium-sized balls. Take one ball and pat it between your palms or on a wet cloth/plastic sheet to form a flat circle.',
          'This takes practice as the dough can break easily. Keep the edges smooth.',
          'Gently lift the rotla and place it on a hot clay or iron tawa.',
          'Cook on medium heat. When one side is slightly done, flip it. Apply a little water on the top surface to keep it moist.',
          'Cook until both sides have brown spots and the rotla is cooked through.',
          'Serve hot with a small dollop of white butter (optional) and garlic chutney.'
        ],
        'tips': 'Bajra is excellent for diabetics as it has a lower glycemic index than wheat or rice.'
      },
      {
        'name': 'Egg White Omelet',
        'carbs': '3g Carbs',
        'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80',
        'protein': '18g',
        'fiber': '1g',
        'prep': '10 min',
        'category': 'Breakfast',
        'ingredients': ['4 Egg Whites', 'Handful of Spinach', '1 Onion', 'Green Chilies', 'Black Pepper'],
        'steps': [
          'Separate the egg whites into a bowl. Whisk them vigorously with a pinch of salt and black pepper until they become slightly frothy.',
          'Finely chop the spinach, onions, and green chilies.',
          'Heat a non-stick frying pan over medium heat and lightly grease it with a few drops of olive oil.',
          'Add the chopped onions and chilies. Sauté for 2 minutes until onions are translucent.',
          'Add the spinach and cook for 1 minute until it wilts.',
          'Pour the whisked egg whites evenly over the vegetables in the pan.',
          'Tilt the pan to ensure the egg whites cover the entire surface.',
          'Cook for 2-3 minutes on medium-low heat until the edges start to lift and the top is set.',
          'Carefully fold the omelet in half using a spatula.',
          'Slide it onto a plate and serve with a slice of toasted multigrain bread.'
        ],
        'tips': 'Adding a tablespoon of milk or water to the egg whites while whisking makes the omelet extra fluffy.'
      },
      {
        'name': 'Roasted Makhana',
        'carbs': '9g Carbs',
        'image': 'https://images.unsplash.com/photo-1599599810694-b5b37304c041?auto=format&fit=crop&w=800&q=80',
        'protein': '3g',
        'fiber': '2g',
        'prep': '5 min',
        'category': 'Snack',
        'ingredients': ['2 cups Phool Makhana', '1/2 tsp Turmeric', 'Black Salt', '1 tsp Ghee/Olive Oil'],
        'steps': [
          'Heat a heavy-bottomed pan or wok over low flame. Add one teaspoon of ghee or olive oil.',
          'Add the makhana (fox nuts) to the pan and start roasting them.',
          'Continue roasting on a very low flame, stirring constantly for 5-7 minutes. Constant stirring is important for even roasting.',
          'To check if they are done, take one makhana and press it; it should break with a distinct "crunch" sound. If it is soft, roast for more time.',
          'Once they are crunchy, add turmeric powder, red chili powder (optional), and black salt.',
          'Toss vigorously for 30 seconds so the spices coat the makhana well. Turn off the heat quickly to prevent the spices from burning.',
          'Let them cool completely; they will become even crispier as they cool.',
          'Store in an airtight container for a healthy anytime snack.'
        ],
        'tips': 'Avoid roasting on high heat as makhana burns very easily from the outside while remaining soft inside.'
      },
      {
        'name': 'Grilled Chicken',
        'carbs': '1g Carbs',
        'image': 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=800&q=80',
        'protein': '30g',
        'fiber': '0g',
        'prep': '25 min',
        'category': 'Dinner',
        'ingredients': ['250g Chicken Breast', 'Lemon Juice', 'Garlic Paste', 'Dried Oregano', 'Salt & Pepper'],
        'steps': [
          'Place the chicken breast between two sheets of plastic wrap and pound it gently with a mallet or heavy pan to ensure even thickness.',
          'In a shallow dish, mix lemon juice, minced garlic, oregano, salt, pepper, and a teaspoon of olive oil.',
          'Place the chicken in the marinade, coat well on both sides, and refrigerate for at least 30 minutes (or up to 4 hours).',
          'Preheat a grill pan or outdoor grill over medium-high heat. Lightly oil the grates.',
          'Place the chicken on the grill. Cook for 6-7 minutes on the first side without moving it to get nice grill marks.',
          'Flip the chicken and cook for another 5-6 minutes until the internal temperature reaches 74°C (165°F) and the juices run clear.',
          'Remove from the grill and let it rest on a cutting board for 5 minutes before slicing. Resting keeps the meat juicy.',
          'Serve with a side of steamed vegetables or a fresh salad.'
        ],
        'tips': 'Avoid overcooking as chicken breast is lean and can become tough and dry very quickly.'
      },
      {
        'name': 'Karela Stir Fry',
        'carbs': '8g Carbs',
        'image': 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=800&q=80',
        'protein': '2g',
        'fiber': '4g',
        'prep': '30 min',
        'category': 'Vegetable',
        'ingredients': ['2-3 Bitter Gourds (Karela)', '3 large Onions', 'Amchur (Dry Mango) Powder', 'Turmeric', 'Coriander Powder'],
        'steps': [
          'Wash and slice the bitter gourds into thin rounds. You can de-seed them if you prefer less bitterness.',
          'Toss the slices with a teaspoon of salt and let them sit for 20 minutes. This draws out the bitter juices.',
          'Squeeze the slices tightly between your palms to remove the liquid, then rinse them once more and pat dry.',
          'Thinly slice 3 large onions. Onions provide sweetness that balances the bitterness of the karela.',
          'Heat 2 teaspoons of oil in a pan. Sauté the onions until they turn golden brown.',
          'Add the karela slices and cook on medium flame for 10-12 minutes, stirring occasionally, until they start to brown and crisp up.',
          'Add turmeric, red chili powder, coriander powder, and a generous teaspoon of amchur powder.',
          'The amchur (mango powder) is essential for cutting through the bitterness.',
          'Cook for another 5 minutes on low heat until everything is well combined and slightly crunchy.',
          'Serve hot with a side of plain dal and roti.'
        ],
        'tips': 'Scraping the outer rough skin of the karela also significantly reduces its bitterness.'
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildRecipeCard(recipe, colorScheme, context);
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, ColorScheme colorScheme, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    recipe['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.restaurant, color: colorScheme.primary, size: 40),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['name'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe['carbs'], 
                    style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSubstitutions(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.blue),
              SizedBox(width: 8),
              Text('Smart Substitutions', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSubItem('White Rice', 'Cauliflower Rice'),
          _buildSubItem('Wheat Flour', 'Almond Flour'),
          _buildSubItem('Sugar', 'Stevia / Monk Fruit'),
          _buildSubItem('Potato', 'Sweet Potato / Pumpkin'),
        ],
      ),
    );
  }

  Widget _buildSubItem(String from, String to) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(from, style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough)),
          const Icon(Icons.arrow_right_alt, size: 16),
          Text(to, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}
