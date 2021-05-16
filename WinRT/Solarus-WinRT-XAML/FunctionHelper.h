#ifndef FUNCTION_HELPER_H
#define FUNCTION_HELPER_H

// func_traits
template <typename T>
struct func_traits : public func_traits<decltype(&std::remove_reference_t<T>::operator())> {};

template <typename Callable, typename Ret, typename... Args>
struct func_traits<Ret(Callable::*)(Args...) const> {
	using ptr_type = Ret(*) (Args...);
	using return_type = Ret;

	template<std::size_t i>
	struct arg
	{
		using type = typename std::tuple_element<i, std::tuple<Args...>>::type;
	};

	template<typename Ret2>
	using cast_return_type = Ret2(*) (Args...);
};

template<typename Ret, typename... Args>
struct func_traits<Ret(&) (Args...)> : public func_traits<Ret(*) (Args...)> {};

template <typename Ret, typename... Args>
struct func_traits<Ret(*) (Args...)>
{
	using ptr_type = Ret(*) (Args...);
	using return_type = Ret;

	template<std::size_t i>
	struct arg
	{
		using type = typename std::tuple_element<i, std::tuple<Args...>>::type;
	};

	template<typename Ret2>
	using cast_return_type = Ret2(*) (Args...);
};



// constexpr counter
template <int N>
struct flag
{
	friend constexpr int adl_flag(flag<N>);
	constexpr operator int() { return N; }
};

template <int N>
struct write
{
	friend constexpr int adl_flag(flag<N>) { return N; }
	static constexpr int value = N;
};

template <int N, int = adl_flag(flag<N>{}) >
constexpr int read(int, flag<N>, int R = read(0, flag<N + 1>{}))
{
	return R;
}

template <int N>
constexpr int read(float, flag<N>)
{
	return N;
}

template <int N = 0>
constexpr int counter(int R = write < read(0, flag<N>{}) > ::value)
{
	return R;
}


// fnptr
template<int nonce = counter()>
class fnptr
{
	//these are to make sure fnptr is never constructed
	//technically the first one should be enough, but compilers are not entirely standard conformant
	explicit fnptr() = delete;
	fnptr(const fnptr&) {}
	~fnptr() = delete;

	template<typename Callable, typename Ret, typename... Args>
	static auto cast(Callable&& c, Ret(*fp)(Args...)) -> decltype(fp)
	{
		using callable_type = std::remove_reference_t<Callable>;
		static callable_type clb{ std::forward<Callable>(c) };
		static bool full = false;
		if (full)
		{
			clb.~callable_type();
			new (&clb) decltype(clb){std::forward<Callable>(c)};
		}
		else
			full = true;
		return [](Args... args) noexcept(noexcept(clb(std::forward<Args>(args)...))) -> Ret
		{
			return Ret(clb(std::forward<Args>(args)...));
		};
	}

public:
	template<typename Signature, typename Callable>
	static Signature* cast(Callable&& c)
	{
		return cast(std::forward<Callable>(c), static_cast<Signature*>(nullptr));
	}

	template<typename Signature, typename Ret, typename... Args>
	static auto cast(Ret(*fp)(Args...))
	{
		static decltype(fp) fnptr;
		fnptr = fp;
		using return_type = typename func_traits<Signature*>::return_type;
		return[](Args... args) noexcept(noexcept(fp(std::forward<Args>(args)...))->return_type
			{
				return return_type(fnptr(std::forward<Args>(args)...));
			});
	}

	template<typename Callable>
	static auto get(Callable&& c)
	{
		return cast(std::forward<Callable>(c), typename func_traits<Callable>::ptr_type{ nullptr });
	}

	template<typename Ret, typename... Args>
	static auto get(Ret(*fp)(Args...))
	{
		return fp;
	}
};

#endif