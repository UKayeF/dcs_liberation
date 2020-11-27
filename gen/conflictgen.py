import logging
import random
from typing import Tuple

from dcs.country import Country
from dcs.mapping import Point

from game.theater.conflicttheater import ConflictTheater, FrontLine
from game.theater.controlpoint import ControlPoint


FRONTLINE_LENGTH = 80000


def _opposite_heading(h):
    return h+180


def _heading_sum(h, a) -> int:
    h += a
    if h > 360:
        return h - 360
    elif h < 0:
        return 360 + h
    else:
        return h


class Conflict:
    def __init__(self,
                 theater: ConflictTheater,
                 from_cp: ControlPoint,
                 to_cp: ControlPoint,
                 attackers_side: str,
                 defenders_side: str,
                 attackers_country: Country,
                 defenders_country: Country,
                 position: Point,
                 heading=None,
                 distance=None,
                 ):

        self.attackers_side = attackers_side
        self.defenders_side = defenders_side
        self.attackers_country = attackers_country
        self.defenders_country = defenders_country

        self.from_cp = from_cp
        self.to_cp = to_cp
        self.theater = theater
        self.position = position
        self.heading = heading
        self.distance = distance
        self.size = to_cp.size

    @property
    def center(self) -> Point:
        return self.position.point_from_heading(self.heading, self.distance / 2)

    @property
    def tail(self) -> Point:
        return self.position.point_from_heading(self.heading, self.distance)

    @property
    def is_vector(self) -> bool:
        return self.heading is not None

    @property
    def opposite_heading(self) -> int:
        return _heading_sum(self.heading, 180)

    def find_ground_position(self, at: Point, heading: int, max_distance: int = 40000) -> Point:
        return Conflict._find_ground_position(at, max_distance, heading, self.theater)

    @classmethod
    def has_frontline_between(cls, from_cp: ControlPoint, to_cp: ControlPoint) -> bool:
        return from_cp.has_frontline and to_cp.has_frontline

    @staticmethod
    def frontline_position(from_cp: ControlPoint, to_cp: ControlPoint, theater: ConflictTheater) -> Tuple[Point, int]:
        frontline = FrontLine(from_cp, to_cp, theater)
        attack_heading = frontline.attack_heading
        position = frontline.position
        return position, _opposite_heading(attack_heading)

    @classmethod
    def flight_frontline_vector(cls, from_cp: ControlPoint, to_cp: ControlPoint, theater: ConflictTheater) -> Tuple[Point, int, int]:
        """Returns the frontline vector without regard for exclusion zones, used in CAS flight plan"""
        frontline = cls.frontline_position(from_cp, to_cp, theater)
        center_position, heading = frontline
        left_position = center_position.point_from_heading(_heading_sum(heading, -90), int(FRONTLINE_LENGTH/2))
        right_position = center_position.point_from_heading(_heading_sum(heading, 90), int(FRONTLINE_LENGTH/2))

        return left_position, _heading_sum(heading, 90), int(right_position.distance_to_point(left_position))


    @classmethod
    def frontline_vector(cls, from_cp: ControlPoint, to_cp: ControlPoint, theater: ConflictTheater) -> Tuple[Point, int, int]:
        """
        Returns a vector for a valid frontline location avoiding exclusion zones.
        """
        center_position, heading = cls.frontline_position(from_cp, to_cp, theater)
        center_position = cls._find_ground_position(center_position, FRONTLINE_LENGTH, _heading_sum(heading, 90), theater)
        left_heading = _heading_sum(heading, 90)
        right_heading =  _heading_sum(heading, -90)
        left_position = cls._extend_ground_position(center_position, int(FRONTLINE_LENGTH / 2), left_heading, theater)
        right_position = cls._extend_ground_position(center_position, int(FRONTLINE_LENGTH / 2), right_heading, theater)
        distance = int(left_position.distance_to_point(right_position))
        return left_position, right_heading, distance

    @classmethod
    def frontline_cas_conflict(cls, attacker_name: str, defender_name: str, attacker: Country, defender: Country, from_cp: ControlPoint, to_cp: ControlPoint, theater: ConflictTheater):
        assert cls.has_frontline_between(from_cp, to_cp)
        position, heading, distance = cls.frontline_vector(from_cp, to_cp, theater)

        return cls(
            position=position,
            heading=heading,
            distance=distance,
            theater=theater,
            from_cp=from_cp,
            to_cp=to_cp,
            attackers_side=attacker_name,
            defenders_side=defender_name,
            attackers_country=attacker,
            defenders_country=defender,
        )

    @classmethod
    def _extend_ground_position(cls, initial: Point, max_distance: int, heading: int, theater: ConflictTheater) -> Point:
        """Finds a valid ground position in one heading from an initial point"""
        pos = initial
        for distance in range(0, int(max_distance), 100):
            if not theater.is_on_land(pos):
                return pos
            pos = initial.point_from_heading(heading, distance)
        if theater.is_on_land(pos):
            return pos
        logging.error("Didn't find ground position ({})!".format(initial))
        return initial

    @classmethod
    def _find_ground_position(cls, initial: Point, max_distance: int, heading: int, theater: ConflictTheater) -> Point:
        """Finds the nearest ground position along a provided heading and it's inverse"""
        pos = initial
        for distance in range(0, int(max_distance), 100):
            if theater.is_on_land(pos):
                return pos
            pos = initial.point_from_heading(heading, distance)
            if theater.is_on_land(pos):
                return pos
            pos = initial.point_from_heading(_opposite_heading(heading), distance)
        logging.error("Didn't find ground position ({})!".format(initial))
        return initial
