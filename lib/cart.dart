import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Home.dart';


class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _getBookmarkedRecipes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final bookmarkedRecipes = snapshot.data!;
            return ListView.builder(
              itemCount: bookmarkedRecipes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.network(bookmarkedRecipes[index].image),
                  title: Text(bookmarkedRecipes[index].title),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Recipe>> _getBookmarkedRecipes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Recipe> bookmarkedRecipes = [];
    for (var key in prefs.getKeys()) {
      if (key != 'counter') {
        var recipeJson = prefs.getString(key);
        if (recipeJson != null) {
          var recipe = Recipe.fromJson(jsonDecode(recipeJson));
          bookmarkedRecipes.add(recipe);
        }
      }
    }
    return bookmarkedRecipes;
  }
}
