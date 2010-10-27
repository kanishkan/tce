/*
    Copyright (c) 2002-2010 Tampere University of Technology.

    This file is part of TTA-Based Codesign Environment (TCE).

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */
/**
 * @file SOPCInterface.hh
 *
 * Declaration of SOPCInterface class.
 *
 * @author Otto Esko 2010 (otto.esko-no.spam-tut.fi)
 * @note rating: red
 */
#ifndef TTA_SOPC_INTERFACE_HH
#define TTA_SOPC_INTERFACE_HH

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include "HDBTypes.hh"

class SOPCInterface {
public:

    SOPCInterface(std::string name, std::string declaration);

    virtual ~SOPCInterface();

    void setProperty(
        const std::string& propertyName,
        const std::string& propertyValue);
    void setProperty(
        const std::string& propertyName,
        int propertyValue);

    void setPort(
        const std::string& hdlName,
        const std::string& interfaceName,
        HDB::Direction direction,
        int width);
    
    std::string name() const;

    bool hasPorts() const;

    virtual void writeInterface(std::ostream& stream) const;
    
    static const std::string SOPC_ADD_INTERFACE;
    static const std::string SOPC_SET_INT_PROPERTY;
    static const std::string SOPC_ADD_INT_PORT;
    static const std::string SOPC_ASSOCIATED_CLOCK;

    static const std::string SOPC_MASTER_INT_NAME;
    static const std::string SOPC_MASTER_INT_DECLR;

    static const std::string SOPC_CLOCK_INT_NAME;
    static const std::string SOPC_CLOCK_INT_DECLR;

    static const std::string SOPC_EXPORT_INT_NAME;
    static const std::string SOPC_EXPORT_INT_DECLR;
    static const std::string SOPC_EXPORT_NAME;

    static const std::string SOPC_IRQ_RECV_INT_NAME;
    static const std::string SOPC_IRQ_RECV_INT_DECLR;

    static const std::string SOPC_INPUT;
    static const std::string SOPC_OUTPUT;
    static const std::string SOPC_BIDIR;
    
protected:

    struct SOPCPort {
        std::string hdlName;
        std::string interfaceName;
        HDB::Direction direction;
        int width;
    };

    typedef std::map<std::string, std::string> PropertyMap;
    typedef std::vector<SOPCPort> PortList;

    const PropertyMap* properties() const;

    const PortList* ports() const;

    void writeProperties(std::ostream& stream) const;
    void writePorts(std::ostream& stream) const;

private:

    SOPCInterface();
    SOPCInterface(const SOPCInterface& old);
    SOPCInterface& operator=(SOPCInterface old);

    std::string name_;
    std::string declaration_;
    PropertyMap properties_;
    PortList ports_; 
};

#endif