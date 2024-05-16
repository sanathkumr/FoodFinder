import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:foodfinder/cart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodFinder extends StatefulWidget {
  const FoodFinder({Key? key}) : super(key: key);

  @override
  State<FoodFinder> createState() => _FoodFinderState();
}

class _FoodFinderState extends State<FoodFinder> {
  TextEditingController _ingredientController = TextEditingController();
  String apikey = "f5c5c4c580904952ad01e1a970286f72";
  List<Recipe> recipie = [];
  String cooking = "";
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    // _loadBookmarks();
  }

  // void _loadBookmarks() async {
  //   prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     recipie.forEach((recipe) {
  //       recipe.bookmarked = prefs!.getBool(recipe.id.toString()) ?? false;
  //     });
  //   });
  // }

  void _toggleBookmark(Recipe recipe) async {
    setState(() {
      recipe.bookmarked = !recipe.bookmarked!;
    });

    if (recipe.bookmarked!) {
      prefs!.setBool(recipe.id.toString(), true);
      Fluttertoast.showToast(msg: 'Recipe bookmarked');
    } else {
      prefs!.remove(recipe.id.toString());
      Fluttertoast.showToast(msg: 'Bookmark removed');
    }
  }

  void fetchRecipes(String ingredients) async {
    try {
      var url = Uri.parse(
          'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredients&apiKey=$apikey');
      var response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apikey',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> recipeData = jsonDecode(response.body);
        List<Recipe> recipes = [];
        recipeData.forEach((data) {
          Recipe recipe = Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
          );
          setState(() {
            recipie.add(recipe);
          });
        });
        print('Data fetched successfully!');
        if (recipes.isEmpty) {
          Fluttertoast.showToast(msg: "No recipes found for '$ingredients'");
        }
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
        print('Reason: ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      Fluttertoast.showToast(msg: "please check your internet");
    } catch (e) {
      Fluttertoast.showToast(msg: "error $e");
    }
  }

  void fetchRecipeInformation(int id) async {
    var url = Uri.parse(
        "https://api.spoonacular.com/recipes/$id/information?includeNutrition=true&apiKey=f5c5c4c580904952ad01e1a970286f72");
    var response = await http.get(url);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      RecipeInformation recipeInfo = RecipeInformation.fromJson(data);
      print("Recipe Title: ${recipeInfo.title}");
      print("Preparation Minutes: ${recipeInfo.preparationMinutes}");
      print("Cooking Minutes: ${recipeInfo.cookingMinutes}");
      print("Health Score: ${recipeInfo.healthScore}");

      // Access extendedIngredients
      for (var ingredient in recipeInfo.extendedIngredients) {
        print(
            "Ingredient: ${ingredient.name}, Original: ${ingredient.original}");
        setState(() {
          cooking = ingredient.original.toString();
        });
      }
    } else {
      print(
          'Failed to fetch recipe information. Status code: ${response.statusCode}');
    }
  }

  List dummyData = ["nithyan"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Finder'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 70,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  fetchRecipes(value);
                });
              },
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Enter Ingredients',
                suffixIcon: IconButton(
                  icon: Icon(Icons.highlight_remove_sharp),
                  onPressed: () {
                    setState(() {
                      recipie.clear(); // Clear the list of recipes
                      _ingredientController.clear(); // Clear the text field
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: recipie.length,
              itemBuilder: (context, index) {
                return ExpansionTile(
                  onExpansionChanged: (value) {
                    fetchRecipeInformation(recipie[index].id);
                  },
                  title: ListTile(
                    leading: Image.network(
                      recipie[index].image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    title: Text(recipie[index].title),
                    subtitle: Text(recipie[index].id.toString()),
                    trailing: IconButton(
                      icon: recipie[index].bookmarked!
                          ? Icon(Icons.bookmark)
                          : Icon(Icons.bookmark_border),
                      onPressed: () {
                        _toggleBookmark(recipie[index]);
                      },
                    ),
                  ),
                  children: [
                    Column(
                      children: [Text(cooking)],
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Recipe {
  final int id;
  final String title;
  final String image;
  bool? bookmarked;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    this.bookmarked = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      image: json['image'],
    );
  }
}

class RecipeInformation {
  final String? title;
  final int? preparationMinutes;
  final int? cookingMinutes;
  final int? healthScore;
  final List<ExtendedIngredient> extendedIngredients;

  RecipeInformation({
    this.title,
    this.preparationMinutes,
    this.cookingMinutes,
    this.healthScore,
    required this.extendedIngredients,
  });

  factory RecipeInformation.fromJson(Map<String, dynamic> json) {
    // Parse extendedIngredients list
    List<ExtendedIngredient> ingredients = [];
    if (json['extendedIngredients'] != null) {
      json['extendedIngredients'].forEach((ingredient) {
        ingredients.add(ExtendedIngredient.fromJson(ingredient));
      });
    }

    return RecipeInformation(
      title: json['title'],
      preparationMinutes: json['preparationMinutes'],
      cookingMinutes: json['cookingMinutes'],
      healthScore: json['healthScore'],
      extendedIngredients: ingredients,
    );
  }
}

class ExtendedIngredient {
  final String? name;
  final String? original;

  ExtendedIngredient({
    this.name,
    this.original,
  });

  factory ExtendedIngredient.fromJson(Map<String, dynamic> json) {
    return ExtendedIngredient(
      name: json['name'],
      original: json['original'],
    );
  }
}
