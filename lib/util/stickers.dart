/*
 *     Copyright (C) 2021  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

enum Stickers {
  danxi_angry,
  danxi_call,
  danxi_cate,
  danxi_dying,
  danxi_egg,
  danxi_fright,
  danxi_heart,
  danxi_hug,
  danxi_overwhelm,
  danxi_roll,
  danxi_roped,
  danxi_sleep,
  danxi_swim,
  danxi_thrill,
  danxi_touchFish,
  danxi_twin;
}

String? getStickerAssetPath(String stickerName) {
  try {
    Stickers sticker = Stickers.values.firstWhere(
            (e) => e.name.toString() == stickerName);
    return "assets/graphics/stickers/${sticker.name}.jpg";
  } catch (error) {
    return null;
  }
}