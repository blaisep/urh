from climesdr cimport *
from libc.stdlib cimport malloc

cdef lms_device_t *_c_device

cpdef list get_device_list():
    """
    Obtain a list of LMS devices attached to the system
    """
    cdef lms_info_str_t *dev_list = <lms_info_str_t *> malloc(256 * sizeof(lms_info_str_t))
    result = LMS_GetDeviceList(dev_list)
    if result > 0:
        return [dev_list[i].decode('UTF-8') for i in range(0, result)]
    else:
        return []

cpdef int open(str info=None):
    """
    Opens device specified by the provided ::lms_dev_info string
    This function should be used to open a device based upon the results of LMS_GetDeviceList()
    device should be initialized to NULL 
    :return 0 on success, (-1) on failure
    """
    cdef char*c_info
    if info is None:
        c_info = NULL
    else:
        info_byte_string = info.encode('UTF-8')
        c_info = <char *> info_byte_string

    return LMS_Open(&_c_device, c_info, NULL)

cpdef int close():
    """
    Close device
    :return:  0 on success, (-1) on failure
    """
    return LMS_Close(_c_device)

cpdef int disconnect():
    """
    Disconnect device but keep configuration cache (device is not deallocated).
    :return:  0 on success, (-1) on failure
    """
    return LMS_Disconnect(_c_device)

cpdef bool is_open(int port):
    return LMS_IsOpen(_c_device, port)

cpdef int init():
    """
    Configure LMS chip with settings that make it ready for operation.
 
    This configuration differs from default LMS chip configuration which is
    described in chip datasheet. In order to load default chip configuration use LMS_Reset().
    :return: 0 on success, (-1) on failure
    """
    return LMS_Init(_c_device)

cpdef int get_num_channels(bool dir_tx):
    """
    Obtain number of RX or TX channels. Use this to determine the maximum
    channel index (specifying channel index is required by most API functions).
    The maximum channel index is N-1, where N is number returned by this function
    :param dir_tx: Select RX or TX
    :return:  Number of channels on success, (-1) on failure
    """
    return LMS_GetNumChannels(_c_device, dir_tx)

cpdef int enable_channel(bool dir_tx, size_t chan, bool enabled):
    """
    Enable or disable specified RX channel.
    
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :param enabled: true(1) to enable, false(0) to disable.
    :return:  0 on success, (-1) on failure
    """
    return LMS_EnableChannel(_c_device, dir_tx, chan, enabled)

cpdef int set_sample_rate(float_type rate, size_t oversample):
    """
    Set sampling rate for all RX/TX channels. Sample rate is in complex samples
    (1 sample = I + Q). The function sets sampling rate that is used for data
    exchange with the host. It also allows to specify higher sampling rate to be
    used in RF by setting oversampling ratio. Valid oversampling values are 1, 2,
    4, 8, 16, 32 or 0 (use device default oversampling value).
    :param rate: sampling rate in Hz to set
    :param oversample: RF oversampling ratio
    :return:  0 on success, (-1) on failure
    """
    LMS_SetSampleRate(_c_device, rate, oversample)

cpdef tuple get_sample_rate(bool dir_tx, size_t chan):
    """
    Get the sampling rate of the specified LMS device RX or TX channel.
    The function obtains the sample rate used in data interface with the host and
    the RF sample rate used by DAC/ADC.
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :return: tuple of host_Hz, rf_Hz or tuple -1,-1 on Error
    """
    cdef float_type host_hz = 0.0  # sampling rate used for data exchange with the host
    cdef float_type rf_hz = 0.0  # RF sampling rate in Hz

    result = LMS_GetSampleRate(_c_device, dir_tx, chan, &host_hz, &rf_hz)
    if result == 0:
        return host_hz, rf_hz
    else:
        return -1, -1

cpdef tuple get_sample_rate_range(bool dir_tx):
    """
    Get the range of supported sampling rates.
    :param dir_tx: Select RX or TX
    :return: Tuple (start, end, step) of Allowed sample rate range in Hz, (-1, -1, -1) on Error
    """
    cdef lms_range_t sample_rate_range
    result = LMS_GetSampleRateRange(_c_device, dir_tx, &sample_rate_range)
    if result == 0:
        return sample_rate_range.min, sample_rate_range.max, sample_rate_range.step
    else:
        return -1, -1, -1

cpdef int set_center_frequency(bool dir_tx, size_t chan, float_type frequency):
    """
    Set RF center frequency in Hz. This automatically selects the appropriate
    antenna (band path) for the desired frequency. In oder to override antenna selection use LMS_SetAntenna().
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :param frequency: Desired RF center frequency in Hz
    :return: 0 on success, (-1) on failure
    """
    return LMS_SetLOFrequency(_c_device, dir_tx, chan, frequency)

cpdef float_type get_center_frequency(bool dir_tx, size_t chan):
    """
    Obtain the current RF center frequency in Hz.
    
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :return: Current RF center frequency in Hz on success, (-1) on failure
    """
    cdef float_type frequency = 0.0
    result = LMS_GetLOFrequency(_c_device, dir_tx, chan, &frequency)
    if result == 0:
        return frequency
    else:
        return -1

cpdef tuple get_center_frequency_range(bool dir_tx):
    """
    Obtain the supported RF center frequency range in Hz.
    
    :param dir_tx: Select RX or TX
    :return: Tuple (start, end, step) of allowed center freq range in Hz, (-1, -1, -1) on Error
    """
    cdef lms_range_t center_freq_range
    result = LMS_GetLOFrequencyRange(_c_device, dir_tx, &center_freq_range)
    if result == 0:
        return center_freq_range.min, center_freq_range.max, center_freq_range.step
    else:
        return -1, -1, -1

cpdef int set_normalized_gain(bool dir_tx, size_t chan, float_type gain):
    """
    Set the combined gain value
    
    This function computes and sets the optimal gain values of various amplifiers
    that are present in the device based on desired normalized gain value.
    
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :param gain: Desired gain, range [0, 1.0], where 1.0 represents the maximum gain
    :return:  0 on success, (-1) on failure
    """
    return LMS_SetNormalizedGain(_c_device, dir_tx, chan, gain)

cpdef float_type get_normalized_gain(bool dir_tx, size_t chan):
    """
    Obtain the current combined gain value
    
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :return: Current gain, range [0, 1.0], where 1.0 represents the maximum gain, or -1 on error
    """
    cdef float_type gain = 0.0
    result = LMS_GetNormalizedGain(_c_device, dir_tx, chan, &gain)
    if result == 0:
        return gain
    else:
        return -1

cpdef int set_lpf_bandwidth(bool dir_tx, size_t chan, float_type bandwidth):
    """
    Configure analog LPF of the LMS chip for the desired RF bandwidth.
    This function automatically enables LPF.
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :param bandwidth: LPF bandwidth in Hz
    :return: 0 on success, (-1) on failure
    """
    return LMS_SetLPFBW(_c_device, dir_tx, chan, bandwidth)

cpdef float_type get_lpf_bandwidth(bool dir_tx, size_t chan):
    """
    Get the currently configured analog LPF RF bandwidth.
    
    :param dir_tx: Select RX or TX
    :param chan: Channel index
    :return: Current LPF bandwidth in Hz on success, (-1) on failure
    """
    cdef float_type bandwidth = 0.0
    result = LMS_GetLPFBW(_c_device, dir_tx, chan, &bandwidth)
    if result == 0:
        return bandwidth
    else:
        return -1

cpdef get_lpf_bandwidth_range(bool dir_tx):
    """
    Get the RF bandwidth setting range supported by the analog LPF of LMS chip
    :param dir_tx: Select RX or TX
    :return: Tuple (start, end, step) of allowed bandwidth values in Hz, (-1, -1, -1) on Error
    """
    cdef lms_range_t bandwidth_range
    result = LMS_GetLPFBWRange(_c_device, dir_tx, &bandwidth_range)
    if result == 0:
        return bandwidth_range.min, bandwidth_range.max, bandwidth_range.step
    else:
        return -1, -1, -1

cpdef calibrate(bool dir_tx, size_t chan, double bw):
    """
    Perform the automatic calibration of specified RX/TX channel. The automatic
    calibration must be run after device configuration is finished because
    calibration values are dependant on various configuration settings.

    automatic RX calibration is not available when RX_LNA_H path is
    selected

    Device should be configured
    :param dir_tx: Select RX or TX
    :param chan: channel index
    :param bw: bandwidth
    :return: 0 on success, (-1) on failure
    """
    return LMS_Calibrate(_c_device, dir_tx, chan, bw, 0)