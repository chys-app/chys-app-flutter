import 'package:chys/app/core/const/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/controller.dart';

class AdoredPost extends StatefulWidget {
  const AdoredPost({super.key});

  @override
  State<AdoredPost> createState() => _AdoredPostState();
}

class _AdoredPostState extends State<AdoredPost> {
  late final AddoredPostsController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller in initState to avoid build-phase conflicts
    controller = Get.put(AddoredPostsController());
    controller.fetchFavoritePosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const AppText(
          text: 'Adored Post',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Container(
            color: Colors.grey[100],
            child: const Center(
              child: Icon(
                Icons.favorite_outline,
                color: Colors.grey,
                size: 48,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchFavoritePosts();
          },
          child:
              controller.favoritePostsRaw.isEmpty
                  ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No favorite posts found.')),
                    ],
                  )
                  : GridView.builder(
                    itemCount: controller.favoritePostsRaw.length,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemBuilder: (context, index) {
                      final post = controller.favoritePostsRaw[index];
                      final List<dynamic> mediaList = post['media'] ?? [];
                      final imageUrl =
                          mediaList.isNotEmpty
                              ? mediaList.first.toString()
                              : 'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg';
                      final creator = post['creator'];
                      final creatorName =
                          creator is Map && creator['name'] != null
                              ? creator['name'].toString()
                              : 'Unknown';
                      final createdAt = post['createdAt']?.toString() ?? '';
                      return InkWell(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.black.withOpacity(0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              // Text content
                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 80,
                                child: Text(
                                  post['description']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // User Info
                              Positioned(
                                left: 20,
                                bottom: 20,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        'https://i.pravatar.cc/150?img=12',
                                      ),
                                      radius: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          creatorName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          createdAt.split('T').first,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        );
      }),
    );
  }
}
