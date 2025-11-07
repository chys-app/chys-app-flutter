import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/pet_profile.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchWidget extends StatelessWidget {
  // Color constants
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _textPrimary = Color(0xFF2C3E50);
  static const Color _textSecondary = Color(0xFF7F8C8D);
  static const Color _primaryColor = Color(0xFF3498DB);
  
  // Data
  final List<PetModel> allPets;
  final List<PetModel> filteredPets;
  final bool isLoadingPets;
  final String searchQuery;
  
  // Callbacks
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(String) onFollowToggle;
  final Function(String) onPetTap;
  final Map<String, bool> followStates;
  final Map<String, bool> followingInProgress;

  const SearchWidget({
    Key? key,
    required this.allPets,
    required this.filteredPets,
    required this.isLoadingPets,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFollowToggle,
    required this.onPetTap,
    required this.followStates,
    required this.followingInProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildSearchResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            style: TextStyle(
              fontSize: 14,
              color: _textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _textSecondary,
                size: 20,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color: _textSecondary,
                        size: 18,
                      ),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _backgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (isLoadingPets && allPets.isEmpty) {
      return _buildLoadingState();
    }

    if (filteredPets.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPetsGrid(context);
  }

  Widget _buildPetsGrid(BuildContext context) {
    if (filteredPets.isEmpty) {
      return _buildEmptyState();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 3;

    return StaggeredGridView.countBuilder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      padding: EdgeInsets.zero,
      itemCount: filteredPets.length,
      itemBuilder: (context, index) {
        final pet = filteredPets[index];
        return _buildPetGridItem(pet);
      },
      staggeredTileBuilder: (index) {
        return const StaggeredTile.count(1, 1.0);
      },
    );
  }

  Widget _buildPetGridItem(PetModel pet) {
    // Get the first photo from photos list, fallback to profilePic
    final String? photoUrl = (pet.photos?.isNotEmpty == true) 
        ? pet.photos!.first 
        : pet.profilePic;
    
    // Debug logging
    developer.log('Building pet grid item: ${pet.name}, photos count: ${pet.photos?.length ?? 0}, photoUrl: $photoUrl');
    
    return GestureDetector(
      onTap: () {
        // Navigate to pet profile - this would need to be passed as callback for pure testing
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Pet image
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: (photoUrl?.isNotEmpty == true)
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        developer.log('Image load error for pet: ${pet.name}, URL: $photoUrl');
                        return _buildPetPlaceholder(pet);
                      },
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        developer.log('Image loading for pet: ${pet.name}');
                        return _buildPetPlaceholder(pet);
                      },
                    )
                  : _buildPetPlaceholder(pet),
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pet.name ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pet.breed?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        pet.breed!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Follow button in top right
            if (pet.user != null)
              Positioned(
                top: 8,
                right: 8,
                child: _buildFollowButton(pet),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetPlaceholder(PetModel pet) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pet.petType?.toLowerCase() == 'dog'
                  ? Icons.pets
                  : pet.petType?.toLowerCase() == 'cat'
                      ? Icons.pets
                      : Icons.pets,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              pet.name ?? 'Unknown',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(PetModel pet) {
    final userId = pet.user;
    
    if (userId == null) {
      return const SizedBox.shrink();
    }
    
    final isFollowing = followStates[userId] ?? false;
    final isInProgress = followingInProgress[userId] ?? false;
    
    developer.log('Building follow button for pet: ${pet.name}, userId: $userId, isFollowing: $isFollowing, isInProgress: $isInProgress');
    
    return GestureDetector(
      key: Key('follow_button_$userId'),
      onTap: isInProgress ? null : () {
        developer.log('Follow button tapped for pet: ${pet.name}, userId: $userId');
        onFollowToggle(userId);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white.withOpacity(0.9) : _primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isInProgress
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFollowing ? _textPrimary : Colors.white,
                  ),
                ),
              )
            : Icon(
                isFollowing ? Icons.check : Icons.person_add,
                size: 16,
                color: isFollowing ? _textPrimary : Colors.white,
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = searchQuery.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: _textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No pets found' : 'No pets yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching 
                ? 'Try searching for a different pet name or breed'
                : 'Pet profiles will appear here',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}