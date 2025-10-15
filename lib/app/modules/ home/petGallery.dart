import 'dart:math';

import 'package:chys/app/core/const/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PetGalleryScreen extends StatelessWidget {
  const PetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> petData = [
      {
        'name': 'Kitty Jenna',
        'location': 'STUTTGART',
        'views': '10.5k views',
        'image': AppImages.cat
      },
      {
        'name': 'Brandon Aminoff',
        'location': 'HAMBURG',
        'views': '10.5k views',
        'image': AppImages.dog
      },
      {
        'name': 'Brandon Aminoff',
        'location': 'HAMBURG',
        'views': '10.5k views',
        'image': AppImages.dog
      },
      {
        'name': 'Kitty Jenna',
        'location': 'STUTTGART',
        'views': '10.5k views',
        'image': AppImages.cat
      },
      {
        'name': 'Brandon Aminoff',
        'location': 'HAMBURG',
        'views': '10.5k views',
        'image': AppImages.cat
      },
      {
        'name': 'Brandon Aminoff',
        'location': 'HAMBURG',
        'views': '10.5k views',
        'image': AppImages.dog
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(AppImages.paw, height: 40),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                      IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {}),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: petData.length,
                  itemBuilder: (context, index) {
                    final pet = petData[index];

                    // Set random height per index
                    final random = Random(index);
                    final int tier =
                        random.nextInt(3); // 0-small, 1-medium, 2-large
                    final double itemHeight = tier == 0
                        ? 160.0
                        : tier == 1
                            ? 220.0
                            : 300.0;

                    return Container(
                      height: itemHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(pet['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                          // info overlay
                          Positioned(
                            left: 8,
                            bottom: 8,
                            right: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 8,
                                      backgroundColor: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pet['name']!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(
                                  pet['location']!,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  pet['views']!,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
