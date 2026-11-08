import 'package:flutter/material.dart';

import '../../../core/utils/app-size.dart';
import 'pet-form-widgets.dart';

class AnimalTypeSection extends StatefulWidget {
  final TextEditingController animalTypeController;
  final TextEditingController breedController;
  final VoidCallback onSelectAnimalType;

  const AnimalTypeSection({
    super.key,
    required this.animalTypeController,
    required this.breedController,
    required this.onSelectAnimalType,
  });

  @override
  State<AnimalTypeSection> createState() => _AnimalTypeSectionState();
}

class _AnimalTypeSectionState extends State<AnimalTypeSection> {
  @override
  void initState() {
    super.initState();
    widget.animalTypeController.addListener(_onAnimalTypeChanged);
  }

  @override
  void dispose() {
    widget.animalTypeController.removeListener(_onAnimalTypeChanged);
    super.dispose();
  }

  void _onAnimalTypeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    final hasAnimalType =
        widget.animalTypeController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 17.s),
      child: Row(
        children: [
          Expanded(
            child: PetCompactLabeledTextField(
              label: '동물 종류',
              hintText: '눌러서 선택',
              controller: widget.animalTypeController,
              onTap: widget.onSelectAnimalType,
            ),
          ),
          if (hasAnimalType) ...[
            SizedBox(width: 16.s),
            Expanded(
              child: PetCompactLabeledTextField(
                label: '세부 종',
                hintText: '눌러서 선택',
                controller: widget.breedController,
                // 반려가족 설정에서는 세부 종은 표시만 하고 수정 불가
                onTap: () {},
              ),
            ),
          ],
        ],
      ),
    );
  }
}
