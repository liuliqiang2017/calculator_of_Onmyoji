"由cython优化的源代码"
# coding: utf-8
import itertools
import sys

from calculator_of_Onmyoji import data_format

def fit_mitama_type(mitama_comb_list, mitama_type_limit, long total_comb,
                     bint all_suit):
    cdef:
        long calculated_count = 0
        int printed_rate = 0
        tuple mitama_comb
        dict mitama, mitama_info, mitama_type_count, comb_data
        unicode mitama_type

    sys.stdout.flush()    

    for mitama_comb in mitama_comb_list:
        calculated_count += 1

        mitama_type_count = {}
        for mitama in mitama_comb:
            mitama_info = mitama.values()[0]
            mitama_type = mitama_info[u'御魂类型']
            mitama_type_count[mitama_type] = mitama_type_count.setdefault(mitama_type, 0) + 1

        if all_suit and 1 in mitama_type_count.values():
                continue

        comb_data = {'sum': {u'御魂计数': mitama_type_count},
                     'info': mitama_comb}

        printed_rate = print_cal_rate(calculated_count,
                                      total_comb, printed_rate)

        yield comb_data


def fit_prop_value(mitama_sum_data, unicode prop_type, float min_value, float max_value):
    cdef dict mitama_enhance = data_format.MITAMA_ENHANCE
    
    cdef:
        dict mitama_data, sum_data, mitama_type_count, mitama_info, suit_info
        tuple mitama_comb
        float prop_value
        int m_count, multi_times
        unicode m_type, p_type

    for mitama_data in mitama_sum_data:
        sum_data = mitama_data["sum"]
        mitama_type_count = sum_data[u'御魂计数']
        mitama_comb = mitama_data['info']
        prop_value = 0.0

        for mitama in mitama_comb:
            mitama_info = mitama.values()[0]
            if mitama_info.get(prop_type, 0):
                prop_value += mitama_info[prop_type]

        for m_type, m_count in mitama_type_count.items():
            if m_count < 2:
                continue
            else:
                suit_info = mitama_enhance[m_type]
                p_type = suit_info[u'加成类型']
                if p_type == prop_type:
                    multi_times = 2 if m_count == 6 else 1  # 6个御魂算2次套装                    
                    prop_value += multi_times * suit_info[u'加成数值']

        if min_value <= prop_value <= max_value:
            yield mitama_data

def cal_mitama_comb_prop(mitama_sum_data):
    cdef:
        dict mitama_data, mitama_type_count, mitama_sum, comb_data, comb_sum
        tuple mitama_comb
    for mitama_data in mitama_sum_data:
        mitama_sum = mitama_data['sum']
        mitama_type_count = mitama_sum[u'御魂计数']
        mitama_comb = mitama_data['info']

        comb_sum = sum_prop(mitama_comb, mitama_type_count)

        comb_data = {'sum': comb_sum,
                     'info': mitama_comb}
        yield comb_data

cdef dict sum_prop(tuple mitama_comb, dict mitama_type_count):
    cdef:
        list prop_type_list
        dict sum_result, mitama_enhance, suit_info, mitama_info, mitama
        unicode m_type, prop_type
        int m_count, multi_times
    prop_type_list = data_format.MITAMA_COL_NAME_ZH[3::]
    sum_result = {k: 0.0 for k in prop_type_list}
    mitama_enhance = data_format.MITAMA_ENHANCE

    for mitama in mitama_comb:

        mitama_info = mitama.values()[0]

        # 计算除套装外的总属性
        for prop_type in prop_type_list:
            sum_result[prop_type] += mitama_info.get(prop_type, 0)

    for m_type, m_count in mitama_type_count.items():
        if m_count >= 2:  # 忽略套装效果
            suit_info = mitama_enhance[m_type]
            multi_times = 2 if m_count == 6 else 1  # 6个同类御魂算2次套装效果
            prop_type = suit_info[u'加成类型']
            if prop_type:
                sum_result[prop_type] += multi_times * suit_info[u'加成数值']

    return sum_result


cdef int print_cal_rate(long calculated_count, long total_comb, int printed_rate, int rate=5):
    '''print cal rate in real time'''
    cdef int cal_rate = int(calculated_count * 100.0 / total_comb)
    if cal_rate > printed_rate and cal_rate % rate == 0:
        print('Calculating rate %s%%' % cal_rate)
        sys.stdout.flush()
        return cal_rate
    return printed_rate