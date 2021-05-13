#ifndef SOLARUS_CUSTOM_DRAW_INFOS_H
#define SOLARUS_CUSTOM_DRAW_INFOS_H

#include "solarus/core/Rectangle.h"
#include "solarus/graphics/BlendMode.h"
#include "solarus/graphics/Color.h"
#include "solarus/core/Platform.h"
#include "solarus/core/Scale.h"

#include "solarus/core/Platform.h"


namespace Custom {

	using namespace Solarus;

	class RegularDrawInfos : public DrawInfos {
	public:
		inline constexpr RegularDrawInfos(const Rectangle& region, const Point& dst_position, const Point& transformation_origin,
			BlendMode blend_mode, uint8_t opacity, double rotation, const Scale& scale, const Color& color,
			const DrawProxy& proxy) :
			DrawInfos(region, dst_position, transformation_origin, blend_mode, opacity, rotation, scale, color, proxy)
		{}
		inline constexpr RegularDrawInfos(const Rectangle& region, const Point& dst_position, const Point& transformation_origin,
			BlendMode blend_mode, uint8_t opacity, double rotation, const Scale& scale,
			const DrawProxy& proxy) :
			RegularDrawInfos(region, dst_position, transformation_origin, blend_mode, opacity, rotation, scale, Color::white, proxy)
		{

		}

		virtual Rectangle dst_rectangle() const override {
			const Point& ototl = -transformation_origin;
			Point otobr = Point(region.get_size()) - transformation_origin;
			Point tcenter = dst_position + transformation_origin;
			Rectangle dst = Rectangle(
				tcenter + ototl * scale,
				tcenter + otobr * scale
			).positive();

			//dst.set_y(dst.get_height());

			return dst;
		}

	};

	class HalfScaledDrawInfos : public DrawInfos {
	public:
		inline constexpr HalfScaledDrawInfos(const Rectangle& region, const Point& dst_position, const Point& transformation_origin,
			BlendMode blend_mode, uint8_t opacity, double rotation, const Scale& scale, const Color& color,
			const DrawProxy& proxy) :
			DrawInfos(region, dst_position, transformation_origin, blend_mode, opacity, rotation, scale, color, proxy)
		{}
		inline constexpr HalfScaledDrawInfos(const Rectangle& region, const Point& dst_position, const Point& transformation_origin,
			BlendMode blend_mode, uint8_t opacity, double rotation, const Scale& scale,
			const DrawProxy& proxy) :
			HalfScaledDrawInfos(region, dst_position, transformation_origin, blend_mode, opacity, rotation, scale, Color::white, proxy)
		{

		}

		virtual Rectangle dst_rectangle() const override {
			const Point& ototl = -transformation_origin;
			Point otobr = Point(region.get_size()) - transformation_origin;
			Point tcenter = dst_position + transformation_origin;
			Rectangle dst = Rectangle(
				tcenter + ototl * scale / 2,
				tcenter + otobr * scale / 2
			).positive();

			return dst;
		}

	};

}


#endif