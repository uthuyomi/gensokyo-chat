"use client";

import { useEffect, useRef, useState } from "react";

type Direction = "left" | "right" | "top" | "bottom";

type FadeInProps = {
  children: React.ReactNode;
  direction?: Direction;
  delay?: number;
  distance?: number;
  className?: string;
};

export default function FadeIn({
  children,
  direction = "left",
  delay = 0,
  distance = 40,
  className = "",
}: FadeInProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { threshold: 0.2 },
    );

    observer.observe(el);

    return () => observer.disconnect();
  }, []);

  const getTransform = () => {
    if (isVisible) return "translate(0,0)";

    switch (direction) {
      case "left":
        return `translateX(-${distance}px)`;
      case "right":
        return `translateX(${distance}px)`;
      case "top":
        return `translateY(-${distance}px)`;
      case "bottom":
        return `translateY(${distance}px)`;
      default:
        return "translate(0,0)";
    }
  };

  return (
    <div
      ref={ref}
      className={className}
      style={{
        opacity: isVisible ? 1 : 0,
        transform: getTransform(),
        transition: `opacity 0.8s ease ${delay}s, transform 0.8s ease ${delay}s`,
      }}
    >
      {children}
    </div>
  );
}
